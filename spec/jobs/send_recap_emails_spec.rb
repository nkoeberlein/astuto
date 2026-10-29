require 'rails_helper'
include ActiveSupport::Testing::TimeHelpers

RSpec.describe SendRecapEmails, type: :job do
  let(:hour) { SendRecapEmails::HOUR }
  let!(:admin) { FactoryBot.create(:user, role: 'admin', notifications_enabled: true, recap_notification_frequency: 'daily') }

  before { allow(UserMailer).to receive(:recap).and_call_original }

  it 'sends a daily recap with the period of the last day' do
    travel_to Time.now.utc.change(hour: hour) do
      FactoryBot.create(:post, created_at: 23.hours.ago)

      described_class.perform_now
      expect(UserMailer).to have_received(:recap).with(user: admin, frequency: 'daily', from: 1.day.ago, to: Time.now.utc).once
    end
  end

  it 'sends recaps to users who chose one, not only to moderators' do
    user = FactoryBot.create(:user, recap_notification_frequency: 'weekly')
    FactoryBot.create(:user, recap_notification_frequency: 'weekly', notifications_enabled: false)
    FactoryBot.create(:user, recap_notification_frequency: 'weekly', status: 'blocked')

    travel_to Time.zone.local(2024, 11, 18, hour, 0, 0) do # Monday
      FactoryBot.create(:post, created_at: 2.days.ago)

      described_class.perform_now
      expect(UserMailer).to have_received(:recap).with(hash_including(user: user, frequency: 'weekly')).once
      expect(UserMailer).to have_received(:recap).once # the post is older than the admin's daily period
    end
  end

  it 'sends nothing when nothing happened' do
    travel_to Time.now.utc.change(hour: hour) do
      FactoryBot.create(:post, created_at: 30.hours.ago)
      FactoryBot.create(:post, created_at: 2.hours.ago, user: admin) # own post

      described_class.perform_now
      expect(UserMailer).not_to have_received(:recap)
    end
  end

  it 'sends weekly recaps only on Mondays and monthly ones only on the 1st' do
    admin.update!(recap_notification_frequency: 'weekly')
    monthly = FactoryBot.create(:user, recap_notification_frequency: 'monthly')
    FactoryBot.create(:post, created_at: Time.zone.local(2024, 11, 19, 10))

    travel_to(Time.zone.local(2024, 11, 20, hour)) { described_class.perform_now } # Wednesday
    expect(UserMailer).not_to have_received(:recap)

    travel_to(Time.zone.local(2024, 11, 25, hour)) { described_class.perform_now } # Monday
    expect(UserMailer).to have_received(:recap).with(hash_including(user: admin, frequency: 'weekly')).once

    travel_to(Time.zone.local(2024, 12, 1, hour)) { described_class.perform_now } # 1st (Sunday)
    expect(UserMailer).to have_received(:recap).with(hash_including(user: monthly, frequency: 'monthly')).once
  end
end
