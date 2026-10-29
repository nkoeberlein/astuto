require 'rails_helper'

RSpec.describe ModerationUsersQuery do
  let!(:older) { FactoryBot.create(:user, full_name: '100% Ada', created_at: 2.days.ago) }
  let!(:newer) { FactoryBot.create(:user, full_name: 'Ada B', created_at: 1.day.ago) }
  let!(:admin) { FactoryBot.create(:admin, full_name: 'Zed') }

  it 'lists admins first, then the newest users, page by page' do
    first = described_class.new(per_page: 2).call
    expect(first.users).to eq([admin, newer])
    expect(first.has_more).to be(true)

    second = described_class.new(page: 2, per_page: 2).call
    expect(second.users).to eq([older])
    expect(second.has_more).to be(false)
  end

  it 'treats LIKE wildcards in the search as plain text' do
    expect(described_class.new(search: '100%').call.users).to eq([older])
  end

  it 'ignores unknown roles and statuses' do
    expect(described_class.new(role: 'superuser', status: 'gone').call.users.size).to eq(3)
  end
end
