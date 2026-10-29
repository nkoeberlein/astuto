# Prometheus metrics in the text exposition format (docs/operations.md). Off unless METRICS_TOKEN
# is set; scrapers send it as a bearer token. Counts cover all feedback spaces, labelled by
# subdomain, so the numbers stay small enough to compute on every scrape.
class MetricsController < ActionController::API
  include ActionController::HttpAuthentication::Token::ControllerMethods

  before_action :authenticate

  def show
    lines = []
    gauge(lines, 'astuto_info', 'Version of this instance', [[{ version: AstutoProject::VERSION }, 1]])
    gauge(lines, 'astuto_tenants', 'Feedback spaces by status', Tenant.group(:status).count.map { |status, n| [{ status: status }, n] })

    subdomains = Tenant.pluck(:id, :subdomain).to_h
    per_tenant = lambda do |scope|
      scope.group(:tenant_id).count.filter_map { |id, n| [{ tenant: subdomains[id] }, n] if subdomains[id] }
    end
    gauge(lines, 'astuto_users', 'Users per feedback space (without deleted)', per_tenant.call(User.unscoped.where.not(status: 'deleted')))
    gauge(lines, 'astuto_posts', 'Posts per feedback space', per_tenant.call(Post.unscoped))
    gauge(lines, 'astuto_posts_pending_approval', 'Posts waiting for moderator approval', per_tenant.call(Post.unscoped.where(approval_status: 'pending')))
    gauge(lines, 'astuto_comments', 'Comments per feedback space', per_tenant.call(Comment.unscoped))
    gauge(lines, 'astuto_votes', 'Votes per feedback space', per_tenant.call(Like.unscoped))

    recent = WebhookDelivery.unscoped.where(is_test: false, created_at: 1.hour.ago..).group(:success).count
    gauge(lines, 'astuto_webhook_deliveries_last_hour', 'Webhook deliveries in the last hour',
          [[{ result: 'success' }, recent.fetch(true, 0)], [{ result: 'failure' }, recent.fetch(false, 0)]])

    sidekiq_metrics(lines) if Rails.application.sidekiq_enabled?

    render plain: lines.join("\n") + "\n", content_type: 'text/plain; version=0.0.4'
  end

  private

    def authenticate
      token = ENV['METRICS_TOKEN'].to_s
      return head(:not_found) if token.empty?

      authenticate_or_request_with_http_token do |given, _options|
        ActiveSupport::SecurityUtils.secure_compare(given, token)
      end
    end

    def gauge(lines, name, help, samples)
      lines << "# HELP #{name} #{help}" << "# TYPE #{name} gauge"
      samples.each do |labels, value|
        rendered = labels.map { |k, v| %(#{k}="#{v.to_s.gsub(/[\\"\n]/) { |c| c == "\n" ? '\\n' : "\\#{c}" }}") }.join(',')
        lines << "#{name}{#{rendered}} #{value}"
      end
    end

    def sidekiq_metrics(lines)
      require 'sidekiq/api'
      queues = Sidekiq::Queue.all
      gauge(lines, 'astuto_sidekiq_queue_size', 'Jobs waiting per queue', queues.map { |q| [{ queue: q.name }, q.size] })
      gauge(lines, 'astuto_sidekiq_queue_latency_seconds', 'Age of the oldest job per queue', queues.map { |q| [{ queue: q.name }, q.latency.round(3)] })
      stats = Sidekiq::Stats.new
      gauge(lines, 'astuto_sidekiq_jobs', 'Retrying and dead jobs', [[{ set: 'retry' }, stats.retry_size], [{ set: 'dead' }, stats.dead_size]])
    rescue StandardError => e
      lines << "# sidekiq metrics unavailable: #{e.class}"
    end
end
