# Tells admins that a new account waits for approval (#362)
module NotifyAdminsOfPendingUser
  def self.call(user)
    return unless user&.pending_approval?

    User.where(role: %w[admin owner], status: 'active', notifications_enabled: true).find_each do |admin|
      AdminMailer.user_pending_approval(admin: admin, user: user).deliver_later
    end
  end
end
