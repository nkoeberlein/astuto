require 'rails_helper'

RSpec.describe WidgetSignInWorkflow do
  let(:config) { WidgetConfig.create!(enabled: true) }

  def sign_in(claims)
    described_class.new(config: config, claims: claims).run
  end

  it 'creates a confirmed account linked to the customer id' do
    user, error = sign_in('email' => 'Ann@Example.com', 'name' => 'Ann Smith', 'id' => 'cust-42')

    expect(error).to be_nil
    expect(user).to have_attributes(email: 'ann@example.com', full_name: 'Ann Smith', widget_external_id: 'cust-42', role: 'user')
    expect(user).to be_confirmed
  end

  it 'finds the account by customer id first, then by email' do
    linked = FactoryBot.create(:user, email: 'old@example.com', widget_external_id: 'cust-1')
    existing = FactoryBot.create(:user, email: 'bob@example.com')

    expect(sign_in('email' => 'new@example.com', 'id' => 'cust-1').first).to eq(linked)
    expect(sign_in('email' => 'bob@example.com', 'id' => 'cust-2').first).to eq(existing)
    expect(existing.reload.widget_external_id).to eq('cust-2')
  end

  it 'refuses an email that belongs to an account linked to another customer id' do
    FactoryBot.create(:user, email: 'bob@example.com', widget_external_id: 'cust-1')

    expect(sign_in('email' => 'bob@example.com', 'id' => 'cust-9')).to eq([nil, 'linked_elsewhere'])
  end

  it 'refuses staff, blocked accounts and unknown people when accounts are not created' do
    FactoryBot.create(:admin, email: 'admin@corp.example')
    FactoryBot.create(:user, email: 'blocked@example.com', status: 'blocked')

    expect(sign_in('email' => 'admin@corp.example')).to eq([nil, 'staff_account'])
    expect(sign_in('email' => 'blocked@example.com')).to eq([nil, 'blocked'])

    config.update!(auto_create_users: false)
    expect(sign_in('email' => 'stranger@example.com')).to eq([nil, 'no_account'])
    expect(sign_in('email' => 'not an email')).to eq([nil, 'invalid_token'])
  end
end
