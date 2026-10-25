# Content Security Policy. Mainly a second line of defence against script
# injection: scripts only from this site (plus Stripe for hosted billing) or
# inline with the per-session nonce. Inline styles stay allowed, because tenant
# custom CSS, server-rendered style attributes and the v2 frontend need them.
#
# CSP_REPORT_ONLY=true reports violations instead of blocking them (emergency
# switch if a custom integration breaks); CSP_REPORT_URI receives the reports.

Rails.application.configure do
  stripe = %w[https://js.stripe.com https://*.js.stripe.com https://checkout.stripe.com]

  config.content_security_policy do |policy|
    policy.default_src :self
    policy.script_src  :self, 'https://js.stripe.com'
    policy.style_src   :self, :unsafe_inline, :https
    policy.img_src     :self, :https, :data
    policy.font_src    :self, :https, :data
    policy.connect_src :self, 'https://api.stripe.com', 'https://checkout.stripe.com'
    policy.frame_src   *stripe
    policy.object_src  :none
    policy.base_uri    :self
    policy.report_uri  ENV['CSP_REPORT_URI'] if ENV['CSP_REPORT_URI'].present?
  end

  # A fresh nonce per response. (A session-based nonce is empty for visitors
  # without a session yet.) The only inline script, the locale in the layout,
  # carries data-turbolinks-eval="false", so Turbolinks doesn't re-run it with
  # an outdated nonce when it swaps pages.
  config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
  # Only scripts: a nonce in style-src would make browsers ignore 'unsafe-inline'
  config.content_security_policy_nonce_directives = %w[script-src]

  config.content_security_policy_report_only = ActiveModel::Type::Boolean.new.cast(ENV['CSP_REPORT_ONLY']) || false
end
