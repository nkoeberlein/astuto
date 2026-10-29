module Api::App::V1
  class RegistrationsController < Api::App::BaseController

    # POST /api/app/v1/registration
    # { fullName, email, password, passwordConfirmation, invitationToken }
    def create
      email = params[:email].to_s.strip

      if params[:invitationToken].present?
        return register_with_invitation(email)
      end

      if tenant_setting.email_registration_policy == 'none_allowed' ||
         (tenant_setting.email_registration_policy == 'custom_domains_allowed' && !tenant_setting.email_domain_allowed?(email))
        return render_error(:forbidden, I18n.t('errors.email_domain_not_allowed'))
      end

      user = User.new(
        full_name: params[:fullName],
        email: email,
        password: params[:password],
        password_confirmation: params[:passwordConfirmation],
        status: 'active'
      )

      return render_error(:unprocessable_content, user.errors.full_messages.join(', ')) unless user.save

      if user.active_for_authentication?
        sign_in(:user, user)
        render status: :created, json: {
          confirmationRequired: false,
          message: I18n.t('devise.registrations.signed_up'),
          session: serialize_session(user)
        }
      else
        render status: :created, json: {
          confirmationRequired: true,
          message: I18n.t('devise.registrations.signed_up_but_unconfirmed'),
          session: serialize_session(nil)
        }
      end
    end

    private

      def register_with_invitation(email)
        invitation = Invitation.find_acceptable(email: email, token: params[:invitationToken].to_s)
        return render_error(:forbidden, I18n.t('errors.unauthorized')) if invitation.nil?

        user = User.new(
          email: email,
          full_name: params[:fullName],
          password: params[:password],
          password_confirmation: params[:passwordConfirmation].presence || params[:password],
          status: 'active'
        )
        user.skip_confirmation

        saved = ActiveRecord::Base.transaction do
          result = user.save
          invitation.update!(accepted_at: Time.current) if result
          result
        end
        return render_error(:unprocessable_content, user.errors.full_messages.join(', ')) unless saved

        sign_in(:user, user)
        render status: :created, json: {
          confirmationRequired: false,
          message: I18n.t('devise.registrations.signed_up'),
          session: serialize_session(user)
        }
      end
  end
end
