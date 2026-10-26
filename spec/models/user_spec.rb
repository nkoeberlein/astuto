require 'rails_helper'

RSpec.describe User, type: :model do
  let(:user) { FactoryBot.build(:user) }
  let(:moderator) { FactoryBot.build(:moderator) }
  let(:admin) { FactoryBot.build(:admin) }
  let(:owner) { FactoryBot.build(:owner) }

  it 'should be valid' do
    expect(user).to be_valid
  end

  it 'has role "user" by default' do
    expect(User.new.role).to eq('user')
  end

  it 'can have the following roles: "user", "moderator", "admin" and "owner"' do
    expect(user.role).to eq('user')
    expect(moderator.role).to eq('moderator')
    expect(admin.role).to eq('admin')
    expect(owner.role).to eq('owner')

    expect(user).to be_valid
    expect(moderator).to be_valid
    expect(admin).to be_valid
    expect(owner).to be_valid
  end

  it 'has status "active" by default' do
    expect(User.new.status).to eq('active')
  end

  it 'can have the following statuses: "active", "blocked" and "deleted"' do
    active = user
    blocked = FactoryBot.build(:blocked)
    deleted = FactoryBot.build(:deleted)

    expect(user.status).to eq('active')
    expect(blocked.status).to eq('blocked')
    expect(deleted.status).to eq('deleted')

    expect(user).to be_valid
    expect(blocked).to be_valid
    expect(deleted).to be_valid
  end

  it 'has a non-nil and non-empty full name' do
    nil_name_user = FactoryBot.build(:user, full_name: nil)
    empty_name_user = FactoryBot.build(:user, full_name: '')

    expect(nil_name_user).to be_invalid
    expect(empty_name_user).to be_invalid
  end

  it 'has a full name between 2 and 64 characters' do
    too_short_user = FactoryBot.build(:user, full_name: 'a' * 1)
    short_user = FactoryBot.build(:user, full_name: 'a' * 2)
    long_user = FactoryBot.build(:user, full_name: 'a' * 64)
    too_long_user = FactoryBot.build(:user, full_name: 'a' * 65)
    
    expect(too_short_user).to be_invalid
    expect(short_user).to be_valid
    expect(long_user).to be_valid
    expect(too_long_user).to be_invalid
  end

  it 'has an email that must contain a @' do
    invalid_email_user = FactoryBot.build(:user, email: 'invalid.email')

    expect(invalid_email_user).to be_invalid
  end

  it 'knows if it has moderator privileges' do
    expect(user).not_to be_a_moderator
    expect(moderator).to be_a_moderator
    expect(admin).to be_a_moderator
    expect(owner).to be_a_moderator
  end

  it 'knows if it has admin privileges' do
    expect(user).not_to be_a_admin
    expect(moderator).not_to be_a_admin
    expect(admin).to be_a_admin
    expect(owner).to be_a_admin
  end

  it 'knows if it has owner privileges' do
    expect(user).not_to be_a_owner
    expect(moderator).not_to be_a_owner
    expect(admin).not_to be_a_owner
    expect(owner).to be_a_owner
  end

  it 'knows if it is active or blocked' do
    expect(user).to be_active

    blocked = FactoryBot.build(:blocked)
    expect(blocked).to be_blocked
  end

  describe 'lockable' do
    let(:user) { FactoryBot.create(:user).tap(&:confirm) }

    def fail_once
      user.valid_for_authentication? { false }
      user.reload
    end

    it 'is not locked by default' do
      expect(user).not_to be_access_locked
    end

    it 'does not lock before maximum_attempts failed attempts' do
      (Devise.maximum_attempts - 1).times { fail_once }

      expect(user).not_to be_access_locked
      expect(user.active_for_authentication?).to be(true)
    end

    it 'locks after maximum_attempts failed attempts' do
      Devise.maximum_attempts.times { fail_once }

      expect(user).to be_access_locked
      expect(user.locked_at).to be_present
      expect(user.unlock_token).to be_present
      expect(user.active_for_authentication?).to be(false)
      expect(user.inactive_message).to eq(I18n.t('devise.failure.locked'))
    end

    it 'sends unlock instructions when it locks' do
      expect do
        Devise.maximum_attempts.times { fail_once }
      end.to have_enqueued_mail(Devise::Mailer, :unlock_instructions)
    end

    it 'does not lock when the credentials are correct' do
      expect(user.valid_for_authentication? { user.valid_password?('password') }).to be(true)

      expect(user.reload).not_to be_access_locked
    end

    it 'clears the counter and token when unlocking' do
      Devise.maximum_attempts.times { fail_once }

      user.unlock_access!

      expect(user.reload.failed_attempts).to eq(0)
      expect(user.unlock_token).to be_nil
      expect(user.locked_at).to be_nil
    end

    it 'unlocks automatically once unlock_in has passed' do
      Devise.maximum_attempts.times { fail_once }
      user.update_column(:locked_at, Devise.unlock_in.ago - 1.minute)

      expect(user.reload).not_to be_access_locked
      expect(user.active_for_authentication?).to be(true)
    end
  end
end
