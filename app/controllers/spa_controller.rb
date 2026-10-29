# Serves the built v2 frontend (frontend/ → public/next) for all its client-side routes,
# injecting server-side <title>, description, Open Graph tags, and favicon for SEO & link previews.
class SpaController < ActionController::Base
  include ApplicationHelper

  INDEX = Rails.root.join('public/next/index.html')

  def show
    response.headers['Cache-Control'] = 'no-cache'

    if INDEX.exist?
      tenant = get_tenant_from_request(request)
      html = tenant ? inject_meta_tags(INDEX.read, tenant) : INDEX.read
      allow_iframe_embedding if tenant && embedded_roadmap?
      render html: html.html_safe, layout: false, content_type: 'text/html'
    else
      render plain: 'The v2 frontend is not built. Run `npm run build` in frontend/ or use the Vite dev server (port 5173).', status: :not_found
    end
  end

  private

    # Other sites may show the roadmap in an iframe (like the legacy /embedded_roadmap).
    # All other pages keep X-Frame-Options: SAMEORIGIN against clickjacking.
    def embedded_roadmap?
      params[:path].to_s == 'embedded_roadmap' && TenantSetting.first_or_create.roadmap_enabled?
    end

    def allow_iframe_embedding
      response.headers.delete('X-Frame-Options')
    end

    # Also sets Current.tenant and the locale for the rest of the request
    def inject_meta_tags(html, tenant)
      Current.tenant = tenant
      I18n.locale = tenant.locale.presence || I18n.default_locale
      setting = TenantSetting.first_or_create

      title, description = resolve_page_meta(tenant, setting)
      escaped_title = ERB::Util.html_escape(title)
      escaped_desc = ERB::Util.html_escape(description)
      escaped_site = ERB::Util.html_escape(tenant.site_name)

      meta_tags = [
        %(<meta name="description" content="#{escaped_desc}" />),
        %(<meta property="og:title" content="#{escaped_title}" />),
        %(<meta property="og:description" content="#{escaped_desc}" />),
        %(<meta property="og:site_name" content="#{escaped_site}" />),
        %(<meta property="og:type" content="website" />)
      ]

      # Block form: a replacement string would read "\0" or "\1" in a title as a backreference
      result = html.sub(%r{<title>.*?</title>}m) { "<title>#{escaped_title}</title>\n    #{meta_tags.join("\n    ")}" }
      if tenant.site_favicon.present?
        escaped_favicon = ERB::Util.html_escape(tenant.site_favicon)
        result = result.sub(%r{<link rel="icon"[^>]*>}) { %(<link rel="icon" href="#{escaped_favicon}" />) }
      end
      result
    end

    def resolve_page_meta(tenant, setting)
      site_name = tenant.site_name.presence || AstutoProject::NAME
      return [site_name, site_name] if setting.is_private

      path = params[:path].to_s
      case path
      when %r{\Aboards/([^/]+)\z}
        slug = Regexp.last_match(1)
        board = Board.friendly.find(slug) rescue nil
        if board
          desc = plain_excerpt(board.description).presence || site_name
          ["#{board.name} · #{site_name}", desc]
        else
          [site_name, site_name]
        end
      when %r{\Aposts/([^/]+)\z}
        slug = Regexp.last_match(1)
        post = Post.where(approval_status: 'approved').friendly.find(slug) rescue nil
        if post
          desc = plain_excerpt(post.description).presence || post.title
          ["#{post.title} · #{site_name}", desc]
        else
          [site_name, site_name]
        end
      when 'roadmap', 'embedded_roadmap'
        ["#{I18n.t('roadmap.title', default: 'Roadmap')} · #{site_name}", site_name]
      when 'moderation/feedback', 'moderation/users'
        ["#{I18n.t('header.menu.moderation', default: 'Moderation')} · #{site_name}", site_name]
      when %r{\Asite_settings/}
        ["#{I18n.t('header.menu.site_settings', default: 'Site settings')} · #{site_name}", site_name]
      when 'login'
        ["#{I18n.t('common.forms.auth.log_in', default: 'Log in')} · #{site_name}", site_name]
      when 'register'
        ["#{I18n.t('common.forms.auth.sign_up', default: 'Sign up')} · #{site_name}", site_name]
      when 'password/forgot'
        ["#{I18n.t('common.forms.auth.forgot_password', default: 'Forgot your password?')} · #{site_name}", site_name]
      when 'password/reset'
        ["#{I18n.t('common.forms.auth.change_password', default: 'Change password')} · #{site_name}", site_name]
      else
        [site_name, site_name]
      end
    end

    def plain_excerpt(markdown)
      markdown.to_s.gsub(/[#*_>`~\[\]()!]/, '').squish.truncate(160)
    end
end
