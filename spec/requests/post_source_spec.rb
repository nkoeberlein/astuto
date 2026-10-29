require 'rails_helper'

RSpec.describe 'Feedback source and posting on behalf', type: :request do
  let(:admin) { FactoryBot.create(:admin).tap(&:confirm) }
  let(:moderator) { FactoryBot.create(:moderator).tap(&:confirm) }
  let(:customer) { FactoryBot.create(:user, email: 'customer@example.com').tap(&:confirm) }
  let(:board) { FactoryBot.create(:board) }

  def create_via_mcp(user, **args)
    Mcp::Tools::CreatePost.run(user: user, board_id: board.id, title: 'Export to CSV', **args)
  end

  it 'lets admins post for an existing user with the source, recorded in the audit log' do
    customer
    result = create_via_mcp(admin, author_email: 'Customer@example.com ', source_url: 'https://acme.slack.com/archives/C1/p123', source_label: 'Slack')

    post = Post.find(result[:post][:id])
    expect(post.user).to eq(customer)
    expect(post).to have_attributes(source_url: 'https://acme.slack.com/archives/C1/p123', source_label: 'Slack')
    expect(post.follows.pluck(:user_id)).to eq([customer.id])
    expect(AuditEvent.sole).to have_attributes(action: 'post.create_for_author', user: admin, source: 'mcp')
  end

  it 'refuses moderators, unknown and blocked authors' do
    customer
    expect { create_via_mcp(moderator, author_email: 'customer@example.com') }.to raise_error(ArgumentError, /Only admins/)
    expect { create_via_mcp(admin, author_email: 'nobody@example.com') }.to raise_error(ArgumentError, /No user/)
    customer.update!(status: 'blocked')
    expect { create_via_mcp(admin, author_email: 'customer@example.com') }.to raise_error(ArgumentError, /No user/)
  end

  it 'accepts only web and mailto links as source' do
    expect { create_via_mcp(moderator, source_url: 'javascript:alert(1)') }.to raise_error(ActiveRecord::RecordInvalid)
    expect { create_via_mcp(moderator, source_url: '/posts/1') }.to raise_error(ActiveRecord::RecordInvalid)
    expect(create_via_mcp(moderator, source_url: 'mailto:customer@example.com')[:post][:source_url]).to eq('mailto:customer@example.com')
  end

  it 'shows the source to moderators only and lets them change it' do
    post_record = FactoryBot.create(:post, board: board, source_url: 'https://tickets.example.com/42', source_label: 'Ticket')

    get "/api/app/v1/posts/#{post_record.slug}"
    expect(response.parsed_body['source']).to be_nil

    sign_in moderator
    get "/api/app/v1/posts/#{post_record.slug}"
    expect(response.parsed_body['source']).to eq('url' => 'https://tickets.example.com/42', 'label' => 'Ticket')

    patch "/api/app/v1/posts/#{post_record.slug}", params: { sourceLabel: 'Zendesk' }, as: :json
    expect(post_record.reload.source_label).to eq('Zendesk')
  end
end
