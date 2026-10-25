module Api::App::V1
  class SessionsController < Api::App::BaseController
    # GET /api/app/v1/session
    def show
      render json: SessionSerializer.call(
        user: current_user,
        tenant: Current.tenant,
        tenant_setting: tenant_setting,
        csrf_token: form_authenticity_token
      )
    end
  end
end
