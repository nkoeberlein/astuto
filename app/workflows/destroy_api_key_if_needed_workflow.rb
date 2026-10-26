# This class is responsible for destroying the API key of a user if they get demoted or blocked

class DestroyApiKeyIfNeededWorkflow
  def initialize(user:)
    @user = user
  end

  def run
    # User.roles orders roles by rank: user < moderator < admin < owner
    demoted = @user.role_changed? &&
              User.roles[@user.role.to_s].to_i < User.roles[@user.role_was.to_s].to_i
    deactivated = !@user.active? || !@user.moderator?

    if demoted || deactivated
      @user.api_key&.destroy
    end
  end
end
