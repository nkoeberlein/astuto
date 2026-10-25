import { connect } from "react-redux";

import GeneralSiteSettingsP from "../components/SiteSettings/General/GeneralSiteSettingsP";
import { updateTenant } from "../actions/Tenant/updateTenant";
import { State } from "../reducers/rootReducer";
import {
  TenantSettingBrandDisplay,
  TenantSettingCollapseBoardsInHeader,
  TenantSettingFeedbackApprovalPolicy,
  TenantSettingLogoLinksTo,
} from "../interfaces/ITenantSetting";

const mapStateToProps = (state: State) => ({
  areUpdating: state.siteSettings.general.areUpdating,
  error: state.siteSettings.general.error,
});

const mapDispatchToProps = (dispatch: any) => ({
  updateTenant(
    siteName: string,
    siteLogo: string,
    siteFavicon: string,
    brandDisplaySetting: TenantSettingBrandDisplay,
    locale: string,
    useBrowserLocale: boolean,
    rootBoardId: number,
    defaultPostSorting: string,
    customLinks: { label: string; url: string }[],
    customDomain: string,
    isPrivate: boolean,
    allowAnonymousFeedback: boolean,
    feedbackApprovalPolicy: TenantSettingFeedbackApprovalPolicy,
    logoLinksTo: TenantSettingLogoLinksTo,
    logoCustomUrl: string,
    roadmapEnabled: boolean,
    showRoadmapInHeader: boolean,
    collapseBoardsInHeader: TenantSettingCollapseBoardsInHeader,
    loginOnlyWithOauth: boolean,
    mailLogoSize: number,
    showVoteCount: boolean,
    showVoteButtonInBoard: boolean,
    hideUnusedStatusesInFilterByStatus: boolean,
    showPoweredBy: boolean,
    authenticityToken: string
  ): Promise<any> {
    return dispatch(updateTenant({
      siteName,
      siteLogo,
      siteFavicon,
      locale,
      customDomain,
      tenantSetting: {
        brand_display: brandDisplaySetting,
        use_browser_locale: useBrowserLocale,
        root_board_id: rootBoardId,
        default_post_sorting: defaultPostSorting,
        custom_links: customLinks,
        is_private: isPrivate,
        allow_anonymous_feedback: allowAnonymousFeedback,
        feedback_approval_policy: feedbackApprovalPolicy,
        logo_links_to: logoLinksTo,
        logo_custom_url: logoCustomUrl,
        roadmap_enabled: roadmapEnabled,
        show_roadmap_in_header: showRoadmapInHeader,
        collapse_boards_in_header: collapseBoardsInHeader,
        login_only_with_oauth: loginOnlyWithOauth,
        mail_logo_size: mailLogoSize,
        show_vote_count: showVoteCount,
        show_vote_button_in_board: showVoteButtonInBoard,
        hide_unused_statuses_in_filter_by_status: hideUnusedStatusesInFilterByStatus,
        show_powered_by: showPoweredBy,
      },
      authenticityToken,
    }));
  },
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(GeneralSiteSettingsP);