module Api::App::V1::Moderation
  # User management (legacy: /moderation/users). Moderators block and unblock users,
  # admins also change roles; the rules are in UserPolicy.
  # Moderators see email addresses here, like in the legacy list.
  class UsersController < Api::App::BaseController
    ASSIGNABLE_ROLES = %w[user moderator admin].freeze
    SETTABLE_STATUSES = %w[active blocked].freeze

    before_action :require_moderator

    # GET /api/app/v1/moderation/users?search=&role=&status=&page=
    def index
      result = ModerationUsersQuery.new(
        search: params[:search],
        role: params[:role],
        status: params[:status],
        page: params[:page] || 1
      ).call

      render json: {
        users: result.users.map { |user| serialize(user) },
        page: result.page,
        hasMore: result.has_more,
        counts: {
          total: User.count,
          active: User.active.count,
          blocked: User.blocked.count,
          deleted: User.deleted.count
        }
      }
    end

    # PATCH /api/app/v1/moderation/users/:id { role?, status? }
    def update
      user = User.find(params[:id])
      return user_not_authorized unless manageable?(user)

      if params.key?(:role)
        return user_not_authorized unless current_user.admin?
        return render_error(:unprocessable_content, I18n.t('errors.unknown')) unless ASSIGNABLE_ROLES.include?(params[:role].to_s)

        user.role = params[:role]
      end

      if params.key?(:status)
        return render_error(:unprocessable_content, I18n.t('errors.unknown')) unless SETTABLE_STATUSES.include?(params[:status].to_s)

        user.status = params[:status]
      end

      saved = ActiveRecord::Base.transaction do
        DestroyApiKeyIfNeededWorkflow.new(user: user).run
        user.save || raise(ActiveRecord::Rollback)
      end
      return render_error(:unprocessable_content, user.errors.full_messages.join(', ')) unless saved

      audit('user.update', user, changes: user.saved_changes.slice('role', 'status')) if user.saved_changes?
      render json: serialize(user)
    end

    # GET /api/app/v1/moderation/users/:id/export (admins): everything stored about the person,
    # e.g. to answer a GDPR access request
    def export
      return user_not_authorized unless current_user.admin?

      user = User.find(params[:id])
      audit('user.export', user)
      send_data JSON.pretty_generate(user.export_data), type: 'application/json',
        filename: "astuto-user-#{user.id}.json", disposition: 'attachment'
    end

    # DELETE /api/app/v1/moderation/users/:id (admins): deletes the account like the person
    # could do themselves (posts and comments stay, shown as "Deleted user")
    def destroy
      user = User.find(params[:id])
      return user_not_authorized unless current_user.admin? && manageable?(user)

      label = user.full_name
      user.anonymize!
      audit('user.delete', user, subject_label: label)
      head :no_content
    end

    private

      # Nobody changes themselves or the owner; deleted accounts stay as they are
      def manageable?(user)
        user.id != current_user.id && !user.owner? && !user.deleted? && UserPolicy.new(current_user, user).update?
      end

      def serialize(user)
        manageable = manageable?(user)
        {
          id: user.id,
          email: user.email,
          fullName: user.full_name_or_email,
          avatarUrl: user.avatar_url,
          role: user.role,
          status: user.status,
          createdAt: user.created_at.iso8601,
          canChangeStatus: manageable,
          canChangeRole: manageable && current_user.admin? && user.active?,
          canExport: current_user.admin?,
          canDelete: manageable && current_user.admin?
        }
      end
  end
end
