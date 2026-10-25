require 'rails_helper'

RSpec.describe Invitation, type: :model do
  let(:invitation) { FactoryBot.build(:invitation) }

  it 'has a valid factory' do
    expect(invitation).to be_valid
  end

  describe '.find_acceptable' do
    let!(:saved) { Invitation.create!(email: 'invited@example.com', token_digest: Digest::SHA256.hexdigest('secret')) }

    it 'finds the invitation for a matching email and token' do
      expect(Invitation.find_acceptable(email: 'invited@example.com', token: 'secret')).to eq(saved)
    end

    it 'returns nil for a wrong token, an accepted or an expired invitation' do
      expect(Invitation.find_acceptable(email: 'invited@example.com', token: 'wrong')).to be_nil
      expect(Invitation.find_acceptable(email: 'invited@example.com', token: '')).to be_nil

      saved.update!(accepted_at: Time.current)
      expect(Invitation.find_acceptable(email: 'invited@example.com', token: 'secret')).to be_nil

      saved.update_columns(accepted_at: nil, updated_at: 4.months.ago)
      expect(Invitation.find_acceptable(email: 'invited@example.com', token: 'secret')).to be_nil
    end
  end
end
