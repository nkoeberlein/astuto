# frozen_string_literal: true

require 'rails_helper'

# type: :job sets up the Rails test hooks ActiveJob::TestHelper relies on (tagged logging)
RSpec.describe SendNotificationForCommentWorkflow, type: :job do
  include ActiveJob::TestHelper

  let(:tenant) { Tenant.first || FactoryBot.create(:tenant) }
  let(:post_owner) { FactoryBot.create(:user, tenant: tenant, notifications_enabled: true) }
  let(:commenter) { FactoryBot.create(:user, tenant: tenant, notifications_enabled: true) }
  let(:post_record) { FactoryBot.create(:post, tenant: tenant, user: post_owner) }

  before do
    Current.tenant = tenant
    Follow.find_or_create_by!(tenant: tenant, post: post_record, user: post_owner)
  end

  it 'delivers post owner notification in background even when Current.tenant is cleared (#431)' do
    comment = FactoryBot.create(:comment, tenant: tenant, post: post_record, user: commenter)

    perform_enqueued_jobs do
      described_class.new(comment: comment).run
      # Simulate a background worker thread where Current.tenant starts unset
      Current.tenant = nil
    end

    Current.tenant = tenant
    expect(ActionMailer::Base.deliveries.map(&:to)).to include([post_owner.email])
  end

  it 'delivers post update notifications only to followers with notifications enabled other than the author' do
    follower_enabled = FactoryBot.create(:user, tenant: tenant, notifications_enabled: true)
    follower_disabled = FactoryBot.create(:user, tenant: tenant, notifications_enabled: false)
    Follow.create!(tenant: tenant, post: post_record, user: follower_enabled)
    Follow.create!(tenant: tenant, post: post_record, user: follower_disabled)
    Follow.create!(tenant: tenant, post: post_record, user: commenter)

    update_comment = FactoryBot.create(
      :comment,
      tenant: tenant,
      post: post_record,
      user: commenter,
      is_post_update: true
    )

    perform_enqueued_jobs do
      described_class.new(comment: update_comment).run
    end

    recipients = ActionMailer::Base.deliveries.flat_map(&:to)
    expect(recipients).to include(post_owner.email, follower_enabled.email)
    expect(recipients).not_to include(follower_disabled.email, commenter.email)
  end
end
