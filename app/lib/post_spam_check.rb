# Anti-spam checks for new posts: a hidden honeypot field that people leave
# empty, and a minimum time the form has to be open before it is sent.
module PostSpamCheck
  MIN_SECONDS_TO_FILL_FORM = 2

  def self.honeypot_filled?(value)
    value.present?
  end

  # fill_ms: milliseconds the form was open, measured in the browser. Measuring
  # a duration (not a timestamp) means a wrong client clock does not matter.
  def self.too_fast?(fill_ms)
    fill_ms.to_i < MIN_SECONDS_TO_FILL_FORM * 1000
  end
end
