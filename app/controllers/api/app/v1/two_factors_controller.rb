module Api::App::V1
  # Two-factor authentication of the signed-in user (Profile settings).
  #   POST   /profile/two_factor               { currentPassword } → secret and QR code (not active yet)
  #   POST   /profile/two_factor/confirm       { code }            → active, backup codes (shown once)
  #   POST   /profile/two_factor/backup_codes  { code }            → new backup codes
  #   DELETE /profile/two_factor               { currentPassword | code }
  class TwoFactorsController < Api::App::BaseController
    before_action :require_user

    def create
      return render_error(:unprocessable_content, I18n.t('two_factor.already_enabled')) if current_user.two_factor_enabled?
      return render_error(:unprocessable_content, wrong_password_message) unless password_ok?

      secret = current_user.start_two_factor_setup!
      uri = current_user.two_factor_provisioning_uri
      render status: :created, json: { secret: secret.scan(/.{4}/).join(' '), otpauthUri: uri, qrCode: qr_code_data_uri(uri) }
    end

    def confirm
      codes = current_user.enable_two_factor!(params[:code])
      return render_error(:unprocessable_content, I18n.t('two_factor.invalid_code')) unless codes

      audit('user.two_factor_enable', current_user) if current_user.moderator?
      render json: { backupCodes: codes }
    end

    def backup_codes
      return render_error(:unprocessable_content, I18n.t('two_factor.invalid_code')) unless current_user.verify_two_factor(params[:code])

      render json: { backupCodes: current_user.regenerate_backup_codes! }
    end

    def destroy
      return render_error(:unprocessable_content, I18n.t('two_factor.not_enabled')) unless current_user.two_factor_enabled?

      allowed = current_user.has_set_password? ? password_ok? : current_user.verify_two_factor(params[:code])
      return render_error(:unprocessable_content, current_user.has_set_password? ? wrong_password_message : I18n.t('two_factor.invalid_code')) unless allowed

      current_user.disable_two_factor!
      audit('user.two_factor_disable', current_user) if current_user.moderator?
      head :no_content
    end

    private

      # Accounts from OAuth logins may have no password; they confirm with a code instead
      def password_ok?
        !current_user.has_set_password? || current_user.valid_password?(params[:currentPassword].to_s)
      end

      def wrong_password_message
        "#{User.human_attribute_name(:current_password)}: #{I18n.t('errors.messages.invalid')}"
      end

      # SVG as a data: URI, so the browser shows it in an <img> without any markup injection
      def qr_code_data_uri(uri)
        svg = RQRCode::QRCode.new(uri).as_svg(module_size: 4, standalone: true, use_path: true, viewbox: true)
        "data:image/svg+xml;base64,#{Base64.strict_encode64(svg)}"
      end
  end
end
