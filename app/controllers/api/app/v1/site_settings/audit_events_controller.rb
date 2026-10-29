module Api::App::V1::SiteSettings
  # Site settings › Audit log: who changed what in moderation and settings. Admins only.
  class AuditEventsController < Api::App::BaseController
    PAGE_SIZE = 50

    before_action :require_admin

    # GET /api/app/v1/site_settings/audit_events?category=post&before=<id>
    # Newest first; nextBefore continues the list, null at the end
    def index
      events = AuditEvent.includes(:user).order(id: :desc)
      events = events.in_category(params[:category]) if AuditEvent::CATEGORIES.include?(params[:category])
      events = events.where(id: ...params[:before].to_i) if params[:before].present?
      page = events.limit(PAGE_SIZE + 1).to_a

      render json: {
        events: page.first(PAGE_SIZE).map { |event| serialize(event) },
        nextBefore: page.size > PAGE_SIZE ? page[PAGE_SIZE - 1].id : nil
      }
    end

    private

      def serialize(event)
        {
          id: event.id,
          createdAt: event.created_at.iso8601,
          action: event.action,
          actorName: event.user&.full_name.presence || event.actor_label,
          subjectType: event.subject_type,
          subjectLabel: event.subject_label,
          subjectPath: subject_path(event),
          changes: event.field_changes.map { |field, (from, to)| { field: field, from: from, to: to } },
          source: event.source,
          ip: event.ip
        }
      end

      # Link to the post when it still exists
      def subject_path(event)
        return unless event.subject_type == 'Post'

        slug = Post.where(id: event.subject_id).pick(:slug)
        "/posts/#{slug}" if slug
      end
  end
end
