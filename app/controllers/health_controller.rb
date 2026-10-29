# Probes for Docker, Kubernetes and load balancers (docs/operations.md):
#   /health/live   the process answers (no dependencies), for liveness probes
#   /health/ready  database reachable, no pending migrations, Redis reachable with Sidekiq;
#                  503 with the failing checks otherwise, for readiness probes
#   /health        database reachable (kept for existing setups)
class HealthController < ActionController::API
  def live
    render plain: 'ok'
  end

  def ready
    checks = { database: database_ok?, migrations: migrations_ok?, redis: redis_ok? }.compact
    render json: { status: checks.values.all? ? 'ok' : 'failing', checks: checks },
           status: checks.values.all? ? :ok : :service_unavailable
  end

  def show
    return render(plain: 'success') if database_ok?

    render plain: 'database unavailable', status: :service_unavailable
  end

  private

    def database_ok?
      ActiveRecord::Base.connection.select_value('SELECT 1') == 1
    rescue StandardError
      false
    end

    def migrations_ok?
      !ActiveRecord::Base.connection_pool.migration_context.needs_migration?
    rescue StandardError
      false
    end

    # nil (left out) without Sidekiq
    def redis_ok?
      return nil unless Rails.application.sidekiq_enabled?

      Sidekiq.redis { |redis| redis.call('PING') } == 'PONG'
    rescue StandardError
      false
    end
end
