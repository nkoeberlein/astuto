require 'rails_helper'

RSpec.describe Devise::Mailer, type: :mailer do
  let!(:user) { FactoryBot.create(:user) }

  describe 'reset_password_instructions' do
    it 'links to the legacy reset page by default' do
      mail = described_class.reset_password_instructions(user, 'tok123')

      expect(mail.body.encoded).to include('/users/password/edit?reset_password_token=tok123')
    end

    it 'links to the v2 reset page with the next template' do
      mail = described_class.reset_password_instructions(user, 'tok123', template_name: 'reset_password_instructions_next')

      expect(mail.body.encoded).to include('/password/reset?reset_password_token=tok123')
      expect(mail.body.encoded).not_to include('/users/password/edit')
    end
  end

  describe 'User#send_next_reset_password_instructions' do
    it 'sends the v2 template with a valid reset token' do
      token = nil
      expect {
        perform_enqueued_jobs { token = user.send_next_reset_password_instructions }
      }.to change { ActionMailer::Base.deliveries.count }.by(1)

      expect(ActionMailer::Base.deliveries.last.body.encoded).to include("/password/reset?reset_password_token=#{token}")
      expect(User.with_reset_password_token(token)).to eq(user)
    end
  end
end
