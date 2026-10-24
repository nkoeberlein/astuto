require 'rails_helper'

RSpec.describe TenantSetting, type: :model do
  let(:tenant_setting) { FactoryBot.build(:tenant_setting) }

  it 'should be valid' do
    expect(tenant_setting).to be_valid
  end

  it 'has a setting brand_display' do
    expect(tenant_setting.brand_display).to eq('name_and_logo')

    tenant_setting.brand_display = 'name_only'
    expect(tenant_setting).to be_valid

    tenant_setting.brand_display = 'logo_only'
    expect(tenant_setting).to be_valid

    tenant_setting.brand_display = 'no_name_no_logo'
    expect(tenant_setting).to be_valid
  end

  it 'has a setting to show vote count' do
    expect(tenant_setting.show_vote_count).to be_truthy
  end

  it 'has a setting to show vote button in board view' do
    expect(tenant_setting.show_vote_button_in_board).to be_truthy
  end

  it 'has a setting to show powered by astuto' do
    expect(tenant_setting.show_powered_by).to be_truthy
  end

  it 'has a setting that contains the board id of the root page' do
    expect(tenant_setting.root_board_id).to eq(0)
  end

  it 'has a setting to show/hide roadmap link in header' do
    expect(tenant_setting.show_roadmap_in_header).to be_truthy
  end

  it 'has a setting to collapse boards in header' do
    expect(tenant_setting.collapse_boards_in_header).to eq('no_collapse')

    tenant_setting.collapse_boards_in_header = 'always_collapse'
    expect(tenant_setting).to be_valid
  end

  it 'has a setting to allow anonymous feedback' do
    expect(tenant_setting.allow_anonymous_feedback).to be_truthy
  end

  it 'has a setting to require approval for feedback' do
    expect(tenant_setting.feedback_approval_policy).to eq('anonymous_require_approval')

    tenant_setting.feedback_approval_policy = 'never_require_approval'
    expect(tenant_setting).to be_valid

    tenant_setting.feedback_approval_policy = 'always_require_approval'
    expect(tenant_setting).to be_valid
  end

  it 'has a setting for making the site private' do
    expect(tenant_setting.is_private).to be_falsey

    tenant_setting.is_private = true
    expect(tenant_setting).to be_valid

    tenant_setting.is_private = false
    expect(tenant_setting).to be_valid
  end

  it 'has a setting for email registration policy' do
    expect(tenant_setting.email_registration_policy).to eq('all_allowed')

    tenant_setting.email_registration_policy = 'none_allowed'
    expect(tenant_setting).to be_valid

    tenant_setting.email_registration_policy = 'custom_domains_allowed'
    expect(tenant_setting).to be_valid
  end

  it 'has a setting for logo links to' do
    expect(tenant_setting.logo_links_to).to eq('root_page')

    tenant_setting.logo_links_to = 'custom_url'
    expect(tenant_setting).to be_valid

    tenant_setting.logo_links_to = 'nothing'
    expect(tenant_setting).to be_valid
  end

  it 'has a setting that can disable the roadmap completely' do
    expect(tenant_setting.roadmap_enabled).to be_truthy

    tenant_setting.roadmap_enabled = false
    expect(tenant_setting).to be_valid
  end

  it 'has a setting for the default post sorting' do
    expect(tenant_setting.default_post_sorting).to eq('trending')

    tenant_setting.default_post_sorting = 'newest'
    expect(tenant_setting).to be_valid

    tenant_setting.default_post_sorting = 'hotness'
    expect(tenant_setting).not_to be_valid
  end

  it 'stores custom header links as list of label and url' do
    expect(tenant_setting.custom_links).to eq([])

    tenant_setting.custom_links = [{ 'label' => 'Docs', 'url' => 'https://example.com/docs' }]
    expect(tenant_setting).to be_valid
    expect(tenant_setting.custom_links).to eq([{ 'label' => 'Docs', 'url' => 'https://example.com/docs' }])

    # entries without url or label are dropped
    tenant_setting.custom_links = [{ 'label' => 'Docs', 'url' => '' }, { 'label' => 'Help', 'url' => 'https://d.io' }, 'junk']
    expect(tenant_setting).to be_valid
    expect(tenant_setting.custom_links).to eq([{ 'label' => 'Help', 'url' => 'https://d.io' }])
  end

  it 'can hide the email/password login' do
    expect(tenant_setting.login_only_with_oauth).to be(false)

    tenant_setting.login_only_with_oauth = true
    expect(tenant_setting).to be_valid
  end

  it 'validates the logo size in emails' do
    expect(tenant_setting.mail_logo_size).to eq(64)

    tenant_setting.mail_logo_size = 100
    expect(tenant_setting).to be_valid

    tenant_setting.mail_logo_size = 0
    expect(tenant_setting).not_to be_valid
  end
end
