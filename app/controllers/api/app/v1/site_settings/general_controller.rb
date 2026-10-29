module Api::App::V1::SiteSettings
  # Site settings › General and › Appearance (custom CSS) (legacy: /site_settings/general and
  # /site_settings/appearance, saved via PATCH /tenants/:id).
  # Admins only; the writable fields come from TenantPolicy and TenantSettingPolicy.
  class GeneralController < Api::App::BaseController
    TENANT_FIELDS = %w[site_name site_logo site_favicon locale custom_domain].freeze
    SETTING_FIELDS = %w[
      brand_display use_browser_locale root_board_id default_post_sorting custom_links
      is_private use_gravatar require_two_factor_for_staff allow_anonymous_feedback feedback_approval_policy trusted_after_posts require_user_approval login_only_with_oauth
      logo_links_to logo_custom_url roadmap_enabled show_roadmap_in_header collapse_boards_in_header
      mail_logo_size show_vote_count show_vote_button_in_board hide_unused_statuses_in_filter_by_status
      show_powered_by custom_css email_registration_policy allowed_email_domains
    ].freeze

    before_action :require_admin

    # GET /api/app/v1/site_settings/general
    def show
      render json: serialize
    end

    # PATCH /api/app/v1/site_settings/general { siteName, locale, isPrivate, ... } (camelCase, all optional)
    def update
      tenant = Current.tenant
      tenant_changes = changes_for(TENANT_FIELDS, TenantPolicy.new(current_user, tenant).permitted_attributes_for_update)
      setting_changes = changes_for(SETTING_FIELDS, TenantSettingPolicy.new(current_user, tenant_setting).permitted_attributes_for_update)

      # Assigning an unknown enum value raises ArgumentError (500)
      invalid = setting_changes.find { |field, value| TenantSetting.defined_enums.key?(field) && !TenantSetting.defined_enums[field].key?(value.to_s) }
      return render_error(:unprocessable_content, "#{TenantSetting.human_attribute_name(invalid[0])}: #{I18n.t('errors.unknown')}") if invalid

      # Blank means "none": custom_domain is unique in the database, a blank favicon uses the default one
      %w[custom_domain site_favicon].each { |field| tenant_changes[field] = nil if tenant_changes.key?(field) && tenant_changes[field].blank? }
      tenant_changes.delete('custom_domain') unless Rails.application.multi_tenancy?

      tenant.assign_attributes(tenant_changes)
      tenant_setting.assign_attributes(setting_changes)

      saved = ActiveRecord::Base.transaction do
        (tenant.save && tenant_setting.save) || raise(ActiveRecord::Rollback)
      end
      unless saved
        errors = tenant.errors.full_messages + tenant_setting.errors.full_messages
        return render_error(:unprocessable_content, errors.join(', '))
      end

      changes = AuditEvent.clean(tenant.saved_changes, 'tenant').merge(AuditEvent.clean(tenant_setting.saved_changes, 'tenant_setting'))
      audit('site_settings.update', tenant, changes: changes, prefix: '') if changes.any?
      render json: serialize
    end

    private

      # snake_case changes from the camelCase body, limited to fields the policy permits
      def changes_for(fields, permitted)
        permitted_names = permitted.map { |entry| entry.is_a?(Hash) ? entry.keys.first.to_s : entry.to_s }
        fields.each_with_object({}) do |field, changes|
          key = field.camelize(:lower)
          next unless params.key?(key) && permitted_names.include?(field)

          changes[field] = field == 'custom_links' ? custom_links_param : params[key]
        end
      end

      def custom_links_param
        Array(params[:customLinks]).filter_map { |link| link.permit(:label, :url).to_h if link.respond_to?(:permit) }
      end

      def serialize
        tenant = Current.tenant
        s = tenant_setting
        {
          siteName: tenant.site_name,
          siteLogo: tenant.site_logo,
          siteFavicon: tenant.site_favicon,
          locale: tenant.locale,
          customDomain: tenant.custom_domain,
          brandDisplay: s.brand_display,
          useBrowserLocale: s.use_browser_locale,
          rootBoardId: s.root_board_id.to_i,
          defaultPostSorting: s.default_post_sorting,
          customLinks: s.custom_links,
          isPrivate: s.is_private,
          useGravatar: s.use_gravatar,
          requireTwoFactorForStaff: s.require_two_factor_for_staff,
          allowAnonymousFeedback: s.allow_anonymous_feedback,
          feedbackApprovalPolicy: s.feedback_approval_policy,
          trustedAfterPosts: s.trusted_after_posts,
          requireUserApproval: s.require_user_approval,
          loginOnlyWithOauth: s.login_only_with_oauth,
          logoLinksTo: s.logo_links_to,
          logoCustomUrl: s.logo_custom_url,
          roadmapEnabled: s.roadmap_enabled,
          showRoadmapInHeader: s.show_roadmap_in_header,
          collapseBoardsInHeader: s.collapse_boards_in_header,
          mailLogoSize: s.mail_logo_size,
          showVoteCount: s.show_vote_count,
          showVoteButtonInBoard: s.show_vote_button_in_board,
          hideUnusedStatusesInFilterByStatus: s.hide_unused_statuses_in_filter_by_status,
          showPoweredBy: s.show_powered_by,
          customCss: s.custom_css,
          emailRegistrationPolicy: s.email_registration_policy,
          allowedEmailDomains: s.allowed_email_domains,
          multiTenancy: Rails.application.multi_tenancy?,
          availableLocales: I18n.available_locales.map(&:to_s)
        }
      end
  end
end
