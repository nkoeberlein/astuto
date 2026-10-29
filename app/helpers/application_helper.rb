module ApplicationHelper
  def get_url_for(url_helper, resource: nil, disallow_custom_domain: false, options: {})
    logger.info { "(start) Call to get_url_for with tenant: #{Current.tenant&.inspect}, url_helper = #{url_helper}, resource = #{resource}, disallow_custom_domain = #{disallow_custom_domain}, options = #{options}" }

    custom_domain = Current.tenant.custom_domain if not disallow_custom_domain and Current.tenant
    subdomain = ''
    host = ''

    if not options[:subdomain].blank?
      subdomain = options[:subdomain]
    end
    if options[:subdomain].blank? && Rails.application.multi_tenancy? && (custom_domain.blank? || disallow_custom_domain)
      subdomain = Current.tenant.subdomain
    end

    if custom_domain.blank? || disallow_custom_domain
      host = Rails.application.base_url
      host = host.gsub(%r{\Ahttps?://|/$}, '')
      host = "#{subdomain}.#{host}" if subdomain.present?
    else
      host = custom_domain
    end

    options[:host] = host

    if Rails.application.base_url.to_s.include?('https') ||
       ActiveModel::Type::Boolean.new.cast(ENV.fetch('ASSUME_SSL', 'false')) ||
       ActiveModel::Type::Boolean.new.cast(ENV.fetch('FORCE_SSL', 'false')) ||
       (defined?(request) && request&.ssl?)
      options[:protocol] = 'https'
    else
      options[:protocol] = 'http'
    end

    logger.info { "(end) Call to get_url_for with options = #{options}, resulting url = #{resource ? url_helper.call(resource, options) : url_helper.call(options)}" }

    resource ? url_helper.call(resource, options) : url_helper.call(options)
  end

  # Language of a request: the feedback space's language, or the browser's preferred one when
  # "use browser language" is on and the app has it (legacy pages, app API, v2 pages)
  def tenant_locale(tenant, tenant_setting, request)
    default = tenant.locale.presence || I18n.default_locale.to_s
    return default unless tenant_setting&.use_browser_locale

    available = I18n.available_locales.map(&:to_s)
    preferred = request.env['HTTP_ACCEPT_LANGUAGE'].to_s.split(',').map { |part| part.split(';').first.to_s.strip }
    preferred.each do |tag|
      exact = available.find { |locale| locale.casecmp?(tag) }
      return exact if exact

      language = tag.split('-').first.to_s.downcase
      return 'zh-CN' if language == 'zh' && available.include?('zh-CN')
      return language if available.include?(language)
    end
    default
  end

  def get_tenant_from_request(request)
    if Rails.application.multi_tenancy?
      request_host = (request.headers['HTTP_X_FORWARDED_HOST'] || request.host).to_s.split(':').first.to_s.downcase
      request_host_splitted = request_host.split('.')
      app_host_splitted = Rails.application.base_url_host.downcase.split('.')

      if request_host_splitted.length > app_host_splitted.length &&
         app_host_splitted == request_host_splitted.last(app_host_splitted.length)
        # Everything in front of the BASE_URL host, also for hosts like feedback.example.co.uk
        # (request.subdomain would depend on tld_length)
        subdomain = request_host_splitted.first(request_host_splitted.length - app_host_splitted.length).join('.')
        return nil if RESERVED_SUBDOMAINS.include?(subdomain)

        tenant = Tenant.find_by(subdomain: subdomain)
      elsif request_host == app_host_splitted.join('.')
        return nil
      else
        tenant = Tenant.find_by(custom_domain: request_host)
      end
    else
      tenant = Tenant.first
    end
    
    tenant
  end

  # Redirect to previous page if it is a local path or an http(s) URL on this
  # host; otherwise use the block (e.g. root). Anything else, like "evil.com",
  # would make redirect_to raise UnsafeRedirectError.
  def safe_return_to_redirect(url)
    return url if SafeUrl.local_path?(url)

    uri = URI.parse(url.to_s)
    same_host = %w[http https].include?(uri.scheme) && uri.host.present? && uri.host == request.host
    same_host ? url : yield
  rescue URI::InvalidURIError
    yield
  end
end
