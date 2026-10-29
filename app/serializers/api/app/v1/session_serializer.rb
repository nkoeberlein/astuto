module Api::App::V1
  # Everything the frontend needs on startup: current user, tenant branding and settings
  module SessionSerializer
    def self.call(user:, tenant:, tenant_setting:, csrf_token:, oauth_start_url:)
      {
        csrfToken: csrf_token,
        user: user && current_user(user),
        # Moderators see AI actions only when a provider is configured
        aiEnabled: user&.moderator? ? Ai::Client.enabled? : false,
        # Badge on the moderation link in the header
        pendingPostsCount: user&.moderator? ? Post.pending.count : nil,
        tenant: {
          siteName: tenant.site_name,
          siteLogo: tenant.site_logo,
          siteFavicon: tenant.site_favicon,
          locale: I18n.locale.to_s,
          oauthProviders: oauth_providers(oauth_start_url),
          # Login with the company directory (POST /api/app/v1/session/ldap), when set up
          ldapLabel: LdapConfig.find_by(enabled: true)&.then { |ldap| ldap.label if ldap.usable? },
          hasChangelog: ChangelogEntry.published.exists?,
          settings: settings(tenant_setting)
        }
      }
    end

    # oauth_start_url: callable that returns the absolute start URL for an OAuth provider
    # SAML single sign-on shows up as one more provider (id 0), started on the current host
    def self.oauth_providers(oauth_start_url)
      providers = OAuth.include_defaults.where(is_enabled: true).order(created_at: :asc).map do |o_auth|
        {
          id: o_auth.id,
          name: o_auth.name,
          logo: o_auth.logo,
          startUrl: oauth_start_url.call(o_auth)
        }
      end
      saml = SamlConfig.find_by(enabled: true)
      providers.unshift({ id: 0, name: saml.label, logo: nil, startUrl: '/saml/start' }) if saml&.usable?
      providers
    end

    def self.current_user(user)
      {
        id: user.id, email: user.email, fullName: user.full_name_or_email, role: user.role, avatarUrl: user.avatar_url,
        twoFactorSetupRequired: user.two_factor_setup_required?
      }
    end

    def self.settings(s)
      {
        brandDisplay: s.brand_display,
        logoLinksTo: s.logo_links_to,
        logoCustomUrl: s.safe_logo_custom_url,
        rootBoardId: s.root_board_id.to_i.positive? ? s.root_board_id : nil,
        showRoadmapInHeader: s.show_roadmap_in_header,
        roadmapEnabled: s.roadmap_enabled,
        defaultPostSorting: s.default_post_sorting,
        customLinks: s.safe_custom_links,
        loginOnlyWithOauth: s.login_only_with_oauth,
        emailRegistrationPolicy: s.email_registration_policy,
        showVoteCount: s.show_vote_count,
        showVoteButtonInBoard: s.show_vote_button_in_board,
        showPoweredBy: s.show_powered_by,
        allowAnonymousFeedback: s.allow_anonymous_feedback,
        isPrivate: s.is_private,
        hideUnusedStatusesInFilterByStatus: s.hide_unused_statuses_in_filter_by_status,
        customCss: s.custom_css
      }
    end
  end
end
