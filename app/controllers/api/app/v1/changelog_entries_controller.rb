module Api::App::V1
  # Changelog (/changelog): everyone reads published entries, moderators also see drafts and
  # write entries. Publishing emails the followers of the linked posts once.
  class ChangelogEntriesController < Api::App::BaseController
    PER_PAGE = 20

    before_action :require_access, only: [:index]
    before_action :require_moderator, except: [:index]

    # GET /api/app/v1/changelog_entries?page=1 (drafts first for moderators)
    def index
      entries = current_user&.moderator? ? ChangelogEntry.all : ChangelogEntry.published
      page = [params[:page].to_i, 1].max
      rows = entries.newest_first.includes(:posts).offset((page - 1) * PER_PAGE).limit(PER_PAGE + 1).to_a

      render json: {
        entries: rows.first(PER_PAGE).map { |entry| ChangelogEntrySerializer.call(entry) },
        page: page,
        hasMore: rows.size > PER_PAGE
      }
    end

    # POST /api/app/v1/changelog_entries { title, body, postIds, published }
    def create
      save(ChangelogEntry.new, 'changelog.create', :created)
    end

    # PATCH /api/app/v1/changelog_entries/:id { title, body, postIds, published } (all optional)
    def update
      save(ChangelogEntry.find(params[:id]), 'changelog.update', :ok)
    end

    # DELETE /api/app/v1/changelog_entries/:id
    def destroy
      entry = ChangelogEntry.find(params[:id])
      entry.destroy!
      audit('changelog.delete', entry, subject_label: entry.title)
      head :no_content
    end

    # GET /api/app/v1/changelog_entries/linkable_posts?search= : approved posts to link,
    # posts with a status first (they are usually the finished ones)
    def linkable_posts
      posts = Post.where(approval_status: 'approved')
      posts = posts.search_by_name_or_description(params[:search]) if params[:search].present?
      posts = posts.reorder(Arel.sql('posts.post_status_id IS NULL'), updated_at: :desc).limit(10)
      render json: posts.map { |post| { id: post.id, title: post.title, slug: post.slug, postStatusId: post.post_status_id } }
    end

    # POST /api/app/v1/changelog_entries/draft { postIds } : AI draft of the text
    # (only when an AI provider is configured, see Ai::Client)
    def draft
      client = Ai::Client.from_env
      return render_error(:not_found, 'AI features are not enabled') unless client.enabled?

      posts = Post.where(id: Array(params[:postIds]).map(&:to_i), approval_status: 'approved').order(:title).limit(30).to_a
      return render_error(:unprocessable_content, I18n.t('errors.unknown')) if posts.empty?

      render json: { body: client.draft_changelog(posts: posts, locale: I18n.locale) }
    rescue Ai::Client::ProviderError, Net::OpenTimeout, Net::ReadTimeout, SocketError, Errno::ECONNREFUSED => e
      Rails.logger.warn("[AI] Changelog draft failed: #{e.class}: #{e.message}")
      render_error(:bad_gateway, I18n.t('errors.unknown'))
    end

    private

      def save(entry, action, status)
        was_published = entry.published?
        workflow = SaveChangelogEntryWorkflow.new(
          entry: entry,
          actor: current_user,
          attributes: params.slice(:title, :body).permit(:title, :body).to_h,
          post_ids: params.key?(:postIds) ? Array(params[:postIds]) : nil,
          published: params.key?(:published) ? ActiveModel::Type::Boolean.new.cast(params[:published]) : nil
        )
        return render_error(:unprocessable_content, entry.errors.full_messages.join(', ')) unless workflow.run

        audit(action, entry, changes: entry.saved_changes.except('followers_notified_at'), subject_label: entry.title)
        audit('changelog.publish', entry, subject_label: entry.title) if entry.published? && !was_published
        render status: status, json: ChangelogEntrySerializer.call(entry.reload)
      end
  end
end
