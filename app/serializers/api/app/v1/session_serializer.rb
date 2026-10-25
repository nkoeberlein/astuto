module Api::App::V1
  # Everything the frontend needs on startup: current user, tenant branding and settings
  module SessionSerializer
    def self.call(user:, tenant:, tenant_setting:, csrf_token:)
      {
        csrfToken: csrf_token,
        user: user && current_user(user),
        tenant: {
          siteName: tenant.site_name,
          siteLogo: tenant.site_logo,
          siteFavicon: tenant.site_favicon,
          locale: I18n.locale.to_s,
          settings: settings(tenant_setting)
        }
      }
    end

    def self.current_user(user)
      { id: user.id, email: user.email, fullName: user.full_name_or_email, role: user.role, avatarUrl: user.gravatar_url }
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
