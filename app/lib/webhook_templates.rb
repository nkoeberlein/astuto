# Ready-made webhook bodies for chat tools (#419), one per service and trigger. The admin picks
# one in the webhook form, which fills method, Content-Type header and body; the URL is the
# incoming-webhook URL from the chat tool. Message texts follow the feedback space's language.
# Bodies are Liquid templates that render valid JSON (texts go through escape_json).
module WebhookTemplates
  SERVICES = %w[slack discord teams].freeze

  # Liquid expressions per message placeholder; link and detail are optional
  MESSAGES = {
    'new_post' => { values: { board: 'board.name', post: 'post.title' }, link: 'post.url', detail: 'post.description' },
    'new_post_pending_approval' => { values: { board: 'board.name', post: 'post.title' }, link: 'post.url', detail: 'post.description' },
    'delete_post' => { values: { id: 'post.id' } },
    'post_status_change' => { values: { post: 'post.title', status: 'post_status.name' }, link: 'post.url' },
    'new_comment' => { values: { author: 'comment_author.full_name', post: 'post.title' }, link: 'post.url', detail: 'comment.body' },
    'new_vote' => { values: { author: 'vote_author.full_name', post: 'post.title' }, link: 'post.url' },
    'new_user' => { values: { user: 'user.full_name' } }
  }.freeze

  DETAIL_LENGTH = 300

  def self.all
    SERVICES.index_with { |service| MESSAGES.keys.index_with { |trigger| body(service, trigger) } }
  end

  def self.body(service, trigger)
    message = MESSAGES.fetch(trigger)
    headline = headline(trigger, message[:values])
    link = message[:link] && "{{ #{message[:link]} | escape_json }}"
    detail = message[:detail] && "{{ #{message[:detail]} | strip_html | truncate: #{DETAIL_LENGTH} | escape_json }}"
    send(service, headline, detail, link)
  end

  # Translated sentence with Liquid placeholders, JSON-escaped around them
  def self.headline(trigger, values)
    marks = values.keys.index_with { |name| "\u0001#{name}\u0001" }
    text = I18n.t("webhook_templates.#{trigger}", **marks).to_json[1...-1]
    values.reduce(text) { |result, (name, expression)| result.gsub("\\u0001#{name}\\u0001", "{{ #{expression} | escape_json }}") }
  end

  def self.slack(headline, detail, link)
    text = [headline, detail && "> #{detail}", link].compact.join('\n')
    pretty({ 'text' => text })
  end

  def self.discord(headline, detail, link)
    text = [headline, detail && "> #{detail}", link].compact.join('\n')
    pretty({ 'content' => text })
  end

  # Microsoft Teams workflow "Post to a channel when a webhook request is received"
  # (Adaptive Card; the old Office 365 connector cards are retired)
  def self.teams(headline, detail, link)
    blocks = [{ 'type' => 'TextBlock', 'text' => headline, 'wrap' => true, 'weight' => 'Bolder' }]
    blocks << { 'type' => 'TextBlock', 'text' => detail, 'wrap' => true } if detail
    card = {
      '$schema' => 'http://adaptivecards.io/schemas/adaptive-card.json', 'type' => 'AdaptiveCard', 'version' => '1.4',
      'body' => blocks
    }
    card['actions'] = [{ 'type' => 'Action.OpenUrl', 'title' => I18n.t('webhook_templates.open'), 'url' => link }] if link
    pretty({ 'type' => 'message', 'attachments' => [{ 'contentType' => 'application/vnd.microsoft.card.adaptive', 'content' => card }] })
  end

  # The pieces are already JSON-escaped Liquid, so the JSON is assembled without escaping them again
  def self.pretty(value, indent = '')
    inner = "#{indent}  "
    case value
    when Hash
      "{\n" + value.map { |key, item| %(#{inner}"#{key}": #{pretty(item, inner)}) }.join(",\n") + "\n#{indent}}"
    when Array
      "[\n" + value.map { |item| "#{inner}#{pretty(item, inner)}" }.join(",\n") + "\n#{indent}]"
    when String then %("#{value}")
    else value.to_json
    end
  end
end
