require 'rails_helper'

RSpec.describe ApiKey, type: :model do
  it 'automatically digest token upon creation' do
    api_key = FactoryBot.build(:api_key)

    expect(api_key.token_digest).to eq(nil)
    
    api_key.save

    expect(api_key.token_digest).not_to eq(nil)
  end

  it 'returns nil for blank tokens without querying by empty digest' do
    expect(ApiKey.find_by_token(nil)).to be_nil
    expect(ApiKey.find_by_token('')).to be_nil
    expect { ApiKey.find_by_token!('') }.to raise_error(ActiveRecord::RecordNotFound)
  end

  describe 'DestroyApiKeyIfNeededWorkflow' do
    it 'destroys the API key when an admin is demoted directly to user' do
      admin = FactoryBot.create(:admin)
      FactoryBot.create(:api_key, user: admin)

      admin.role = 'user'
      DestroyApiKeyIfNeededWorkflow.new(user: admin).run

      expect(admin.reload.api_key).to be_nil
    end

    it 'destroys the API key when both role and status change at once' do
      moderator = FactoryBot.create(:moderator)
      FactoryBot.create(:api_key, user: moderator)

      moderator.role = 'admin'
      moderator.status = 'blocked'
      DestroyApiKeyIfNeededWorkflow.new(user: moderator).run

      expect(moderator.reload.api_key).to be_nil
    end
  end
end
