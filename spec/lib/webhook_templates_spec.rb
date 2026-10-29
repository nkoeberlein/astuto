require 'rails_helper'

RSpec.describe WebhookTemplates do
  def render(service, trigger)
    context = CreateLiquidTemplateContextWorkflow.new(webhook_trigger: trigger, is_test: true).run
    JSON.parse(Liquid::Template.parse(described_class.body(service, trigger), error_mode: :strict).render!(context))
  end

  it 'renders valid JSON for every service and trigger' do
    described_class::SERVICES.product(Webhook.triggers.keys).each do |service, trigger|
      expect { render(service, trigger) }.not_to raise_error, "#{service} / #{trigger}"
    end
  end

  it 'builds Slack and Discord messages with a link to the post' do
    slack = render('slack', 'new_comment')['text']
    expect(slack).to start_with('Test User Comment Author commented on Example post for webhook testing')
    expect(slack).to include("\n> This is just an example comment", "\nhttp")
    expect(render('discord', 'new_post')['content']).to start_with('New feedback in Example board for webhook testing:')
  end

  it 'builds an Adaptive Card for Microsoft Teams' do
    card = render('teams', 'post_status_change').dig('attachments', 0, 'content')

    expect(card['type']).to eq('AdaptiveCard')
    expect(card.dig('body', 0, 'text')).to eq('Example post for webhook testing is now: Example post status')
    expect(card.dig('actions', 0, 'url')).to start_with('http')
  end

  it 'keeps quotes in names from breaking the JSON' do
    context = CreateLiquidTemplateContextWorkflow.new(webhook_trigger: 'new_user', is_test: true).run
    context['user']['full_name'] = 'Ann "the \\ tester"'
    body = Liquid::Template.parse(described_class.body('slack', 'new_user'), error_mode: :strict).render!(context)

    expect(JSON.parse(body)['text']).to eq('New user: Ann "the \\ tester"')
  end

  it 'writes the messages in the language of the feedback space' do
    I18n.with_locale(:de) { expect(described_class.body('slack', 'new_vote')).to include('hat für') }
  end
end
