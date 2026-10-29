module Api::App::V1
  # Profile settings of the signed-in user (legacy: /users/edit, Devise registrations#update/destroy).
  # Name and notifications change freely; email and password need the current password,
  # like deleting the account. API keys are for moderators.
  class ProfilesController < Api::App::BaseController
    include ApiKeysHelper

    before_action :require_user

    # GET /api/app/v1/profile
    def show
      render json: serialize(current_user)
    end

    # PATCH /api/app/v1/profile { fullName, notificationsEnabled, recapNotificationFrequency,
    #                             email, password, passwordConfirmation, currentPassword }
    def update
      user = current_user
      attributes = {}
      attributes[:full_name] = params[:fullName] if params.key?(:fullName)
      attributes[:notifications_enabled] = params[:notificationsEnabled] if params.key?(:notificationsEnabled)
      if params.key?(:recapNotificationFrequency)
        return render_error(:unprocessable_content, I18n.t('errors.unknown')) unless User.recap_notification_frequencies.key?(params[:recapNotificationFrequency].to_s)

        attributes[:recap_notification_frequency] = params[:recapNotificationFrequency]
      end

      email_change = params[:email].present? && params[:email].to_s.strip.casecmp(user.email) != 0
      password_change = params[:password].present?

      if email_change || password_change
        return render_error(:forbidden, I18n.t('common.forms.auth.no_password_set')) unless user.has_set_password?
        return render_error(:unprocessable_content, wrong_password_message) unless user.valid_password?(params[:currentPassword].to_s)
      end

      if email_change
        email = params[:email].to_s.strip
        if tenant_setting.email_registration_policy == 'custom_domains_allowed' && !tenant_setting.email_domain_allowed?(email)
          return render_error(:unprocessable_content, I18n.t('errors.email_domain_not_allowed'))
        end

        # Without SMTP in production, apply the change at once instead of waiting for an
        # undeliverable confirmation email (#476, same as the legacy profile page)
        user.skip_reconfirmation! if Rails.env.production? && ENV['EMAIL_DELIVERY_METHOD'] != 'smtp'
        attributes[:email] = email
      end

      if password_change
        attributes[:password] = params[:password]
        attributes[:password_confirmation] = params[:passwordConfirmation].to_s
      end

      return render_error(:unprocessable_content, user.errors.full_messages.join(', ')) unless user.update(attributes)

      # A new password ends other sessions (Devise); this one stays signed in
      bypass_sign_in(user) if password_change
      render json: serialize(user)
    end

    # DELETE /api/app/v1/profile { currentPassword }: soft delete, like the legacy page
    def destroy
      user = current_user
      if user.has_set_password? && !user.valid_password?(params[:currentPassword].to_s)
        return render_error(:unprocessable_content, wrong_password_message)
      end
      return render_error(:forbidden, I18n.t('errors.unauthorized')) if user.owner?

      user.anonymize!
      sign_out(user)

      render json: serialize_session(nil)
    end

    # GET /api/app/v1/profile/export: everything stored about the signed-in person (GDPR)
    def export
      send_data JSON.pretty_generate(current_user.export_data), type: 'application/json',
        filename: 'astuto-my-data.json', disposition: 'attachment'
    end

    # POST /api/app/v1/profile/api_key: a new API key (moderators); the old one stops working
    def api_key
      return render_error(:forbidden, I18n.t('errors.unauthorized')) unless current_user.moderator?
      return render_error(:forbidden, I18n.t('two_factor.setup_required')) if current_user.two_factor_setup_required?

      key = ActiveRecord::Base.transaction do
        current_user.api_key&.destroy!
        ApiKey.create!(user: current_user)
      end
      audit('api_key.create', current_user)
      render status: :created, json: { apiKey: key.token, masked: token_mask(key.token_prefix) }
    end

    private

      def wrong_password_message
        "#{User.human_attribute_name(:current_password)}: #{I18n.t('errors.messages.invalid')}"
      end

      def serialize(user)
        {
          fullName: user.full_name.to_s,
          email: user.email,
          unconfirmedEmail: user.unconfirmed_email,
          hasSetPassword: user.has_set_password?,
          notificationsEnabled: user.notifications_enabled,
          recapNotificationFrequency: user.recap_notification_frequency,
          recapAvailable: Rails.application.sidekiq_enabled?,
          canHaveApiKey: user.moderator?,
          twoFactorEnabled: user.two_factor_enabled?,
          twoFactorRequired: user.moderator? && tenant_setting.require_two_factor_for_staff,
          backupCodesLeft: user.two_factor_enabled? ? user.backup_codes_left : 0,
          apiKey: user.moderator? && user.api_key ? token_mask(user.api_key.token_prefix) : nil,
          canDeleteAccount: !user.owner?
        }
      end
  end
end
