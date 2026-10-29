module Api::App::V1::SiteSettings
  # Site settings › Invitations (legacy: /site_settings/invitations, /invitations). Admins only.
  # Links lead to the v2 sign-up page, which accepts the invitation token.
  class InvitationsController < Api::App::BaseController
    before_action :require_admin

    # GET /api/app/v1/site_settings/invitations
    def index
      render json: Invitation.order(updated_at: :desc).map { |invitation| serialize(invitation) }
    end

    # POST /api/app/v1/site_settings/invitations { to: [emails], subject, body }
    def create
      result = workflow.run
      return render_error(:unprocessable_content, error_message(result.error)) if result.error

      render json: { sent: result.sent, skipped: result.skipped }
    end

    # POST /api/app/v1/site_settings/invitations/test { subject, body }: test email to oneself
    def test
      error = workflow.test(current_user.email)
      return render_error(:unprocessable_content, error_message(error)) if error

      render json: { sentTo: current_user.email }
    end

    private

      def workflow
        SendInvitationsWorkflow.new(
          to: params[:to],
          subject: params[:subject],
          body: params[:body],
          link_for: lambda { |token, email|
            get_url_for(method(:spa_register_url), options: { invitation_token: token, email: email })
          }
        )
      end

      def error_message(error)
        case error
        when :too_many then I18n.t('site_settings.invitations.too_many_emails', count: SendInvitationsWorkflow::MAX_RECIPIENTS)
        when :link_missing then I18n.t('site_settings.invitations.invitation_link_not_found')
        end
      end

      def serialize(invitation)
        status =
          if invitation.accepted_at.present? then 'accepted'
          elsif invitation.expired? then 'expired'
          else 'pending'
          end
        { id: invitation.id, email: invitation.email, status: status, sentAt: invitation.updated_at.iso8601, acceptedAt: invitation.accepted_at&.iso8601 }
      end
  end
end
