# Content Security Policy. Mainly a second line of defence against script
# injection: scripts only from this site or inline with the per-response nonce. Inline styles stay allowed, because tenant
# custom CSS, server-rendered style attributes and the v2 frontend need them.
#
# CSP_REPORT_ONLY=true reports violations instead of blocking them (emergency
# switch if a custom integration breaks); CSP_REPORT_URI receives the reports.

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.script_src  :self
    policy.style_src   :self, :unsafe_inline, :https
    policy.img_src     :self, :https, :data
    policy.font_src    :self, :https, :data
    policy.connect_src :self
    policy.frame_src   :self
    policy.object_src  :none
    policy.base_uri    :self
    policy.report_uri  ENV['CSP_REPORT_URI'] if ENV['CSP_REPORT_URI'].present?
  end

  # A fresh nonce per response (a session-based nonce is empty for visitors
  # without a session yet). No page has inline scripts today; one added later
  # needs `javascript_tag nonce: true`.
  config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
  # Only scripts: a nonce in style-src would make browsers ignore 'unsafe-inline'
  config.content_security_policy_nonce_directives = %w[script-src]

  config.content_security_policy_report_only = ActiveModel::Type::Boolean.new.cast(ENV['CSP_REPORT_ONLY']) || false
end
