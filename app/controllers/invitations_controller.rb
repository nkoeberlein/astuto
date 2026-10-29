class InvitationsController < ApplicationController
  before_action :authenticate_admin

  def create
    result = workflow.run

    status = result.sent > 0 ? :ok : :unprocessable_entity
    render json: { num_invitations_sent: result.sent }, status: status
  end

  def test
    workflow.test(invitation_params[:to])

    render json: {}, status: :ok
  end

  private

    def workflow
      SendInvitationsWorkflow.new(
        to: invitation_params[:to],
        subject: invitation_params[:subject],
        body: invitation_params[:body],
        link_for: lambda { |token, email|
          get_url_for(method(:new_user_registration_url), options: { invitation_token: token, email: email })
        }
      )
    end

    def invitation_params
      params.require(:invitations).tap do |invitation|
        invitation.require(:to)
        invitation.require(:subject)
        invitation.require(:body)
      end
    end
end
