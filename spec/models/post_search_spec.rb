# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Post, '.search_by_name_or_description and .similar_to', type: :model do
  let(:tenant) { Tenant.first || FactoryBot.create(:tenant) }
  let(:board) { FactoryBot.create(:board, tenant: tenant) }

  before do
    Current.tenant = tenant
  end

  let!(:dark_mode_post) do
    FactoryBot.create(
      :post,
      tenant: tenant,
      board: board,
      title: 'Dark mode for the main dashboard',
      description: 'Allow users to switch between light and dark color schemes.',
      approval_status: 'approved'
    )
  end

  let!(:sso_post) do
    FactoryBot.create(
      :post,
      tenant: tenant,
      board: board,
      title: 'SAML Single Sign-On integration',
      description: 'Enterprise identity provider login via SAML 2.0.',
      approval_status: 'approved'
    )
  end

  describe '.search_by_name_or_description' do
    it 'matches multi-word queries across title and description via PostgreSQL full-text search' do
      results = described_class.search_by_name_or_description('dashboard color schemes')
      expect(results).to include(dark_mode_post)
      expect(results).not_to include(sso_post)
    end

    it 'still matches partial substrings via ILIKE fallback' do
      results = described_class.search_by_name_or_description('Single Sign')
      expect(results).to include(sso_post)
      expect(results).not_to include(dark_mode_post)
    end
  end

  describe '.similar_to' do
    it 'finds potential duplicates sharing significant words and ranks the closest match first' do
      results = described_class.similar_to('Please add dark mode theme to dashboard', board_id: board.id)
      expect(results.first).to eq(dark_mode_post)
      expect(results).not_to include(sso_post)
    end

    it 'returns empty relation when input has no significant tokens' do
      expect(described_class.similar_to('a b')).to be_empty
    end
  end
end
