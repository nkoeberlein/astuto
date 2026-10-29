require 'rails_helper'

RSpec.describe 'Tags on posts', type: :request do
  let(:moderator) { FactoryBot.create(:moderator).tap(&:confirm) }
  let(:board) { FactoryBot.create(:board) }
  let!(:mobile) { Tag.create!(name: 'Mobile') }
  let!(:billing) { Tag.create!(name: 'Billing') }
  let!(:post_record) { FactoryBot.create(:post, board: board, title: 'Offline mode') }

  it 'lets moderators set the tags of a post, audited' do
    sign_in moderator
    patch "/api/app/v1/posts/#{post_record.slug}", params: { tagIds: [billing.id, mobile.id] }, as: :json

    expect(response.parsed_body['tagIds']).to eq([mobile.id, billing.id])
    expect(AuditEvent.last.field_changes['post.tag_ids']).to eq([[], [mobile.id, billing.id].sort])

    patch "/api/app/v1/posts/#{post_record.slug}", params: { tagIds: [] }, as: :json
    expect(post_record.reload.tags).to be_empty
  end

  it 'refuses unknown tags and ignores tags from people who are not moderators' do
    sign_in moderator
    patch "/api/app/v1/posts/#{post_record.slug}", params: { tagIds: [0] }, as: :json
    expect(response).to have_http_status(:unprocessable_content)

    author = post_record.user.tap(&:confirm)
    sign_out moderator
    sign_in author
    patch "/api/app/v1/posts/#{post_record.slug}", params: { tagIds: [mobile.id] }, as: :json
    expect(response).to have_http_status(:ok)
    expect(post_record.reload.tags).to be_empty
  end

  it 'shows tags in board lists and filters by them' do
    post_record.tags << mobile
    FactoryBot.create(:post, board: board, title: 'Invoices as PDF').tags << billing
    FactoryBot.create(:post, board: board, title: 'Untagged post')

    get "/api/app/v1/boards/#{board.slug}/posts"
    expect(response.parsed_body['posts'].to_h { |p| [p['title'], p['tagIds']] }).to include('Offline mode' => [mobile.id], 'Untagged post' => [])

    get "/api/app/v1/boards/#{board.slug}/posts", params: { tag_ids: [mobile.id, billing.id] }
    expect(response.parsed_body['posts'].map { |p| p['title'] }).to contain_exactly('Offline mode', 'Invoices as PDF')
  end

  it 'gives the kept post the tags of a merged duplicate' do
    duplicate = FactoryBot.create(:post, board: board)
    duplicate.tags << billing
    post_record.tags << mobile

    MergePostsWorkflow.new(source: duplicate, target: post_record, actor: moderator).run!

    expect(post_record.reload.tags).to eq([mobile, billing])
  end
end
