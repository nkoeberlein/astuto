class User < ApplicationRecord
  include TenantOwnable
  include User::TwoFactor
  
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :confirmable,
         :trackable, :lockable
    
  validates_confirmation_of :password
  
  has_many :posts, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_one :api_key, dependent: :destroy
  has_many :follows, dependent: :destroy

  enum :role, [:user, :moderator, :admin, :owner]
  enum :status, [:active, :blocked, :deleted]

  enum :recap_notification_frequency, [:never, :daily, :weekly, :monthly]

  after_initialize :set_default_role, if: :new_record?
  after_initialize :set_default_status, if: :new_record?
  after_create :run_webhooks

  validates :full_name, presence: true, length: { in: 2..64 }
  validates :email,
    presence: true,
    uniqueness: { scope: :tenant_id, case_sensitive: false },
    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, allow_blank: true, length: { in: 6..128 }
  validates :password, presence: true, on: :create

  def set_default_role
    self.role ||= :user
  end

  def set_default_status
    self.status ||= :active
  end

  def active_for_authentication?
    super && active?
  end

  def inactive_message
    return I18n.t('devise.failure.locked') if access_locked?

    active? ? super : I18n.t('errors.user_blocked_or_deleted')
  end

  # Override Devise::Confirmable#after_confirmation
  # Used to change tenant status from pending to active on owner email confirmation
  def after_confirmation
    tenant = self.tenant

    if tenant.status == "pending" and tenant.users.count == 1
      tenant.status = "active"
      tenant.save
    end
  end

  def skip_confirmation
    skip_confirmation!
    skip_confirmation_notification!
    skip_reconfirmation!
  end

  # Deliver Devise emails (confirmation, password reset, email changed) via ActiveJob (#444)
  def send_devise_notification(notification, *args)
    devise_mailer.send(notification, self, *args).deliver_later
  end

  # Like Devise's send_reset_password_instructions, but the email links to the
  # password reset page of the v2 frontend (/password/reset)
  def send_next_reset_password_instructions
    token = set_reset_password_token
    send_devise_notification(:reset_password_instructions, token, template_name: 'reset_password_instructions_next')
    token
  end

  # Gravatar identifies avatars by the MD5 of the trimmed, lowercased email
  def self.gravatar_hash(email)
    return nil if email.blank?

    Digest::MD5.hexdigest(email.to_s.strip.downcase)
  end

  def gravatar_url
    "https://secure.gravatar.com/avatar/#{User.gravatar_hash(email)}?d=retro"
  end

  # Avatar from Gravatar (the request reveals the email hash to gravatar.com), unless the feedback
  # space switched it off; the frontend then shows the initial
  def avatar_url
    setting = Current.tenant&.tenant_setting
    (setting.nil? || setting.use_gravatar) ? gravatar_url : nil
  end

  # Account deletion (by the person or an admin, GDPR): the account stays as "Deleted user" so
  # posts and comments keep their place, but nothing identifies the person any more
  def anonymize!
    transaction do
      self.status = 'deleted'
      self.email = "#{SecureRandom.alphanumeric(16)}@deleted.com"
      self.full_name = I18n.t('defaults.deleted_user_full_name')
      self.unconfirmed_email = nil
      self.current_sign_in_ip = nil
      self.last_sign_in_ip = nil
      self.oauth_token = nil
      self.notifications_enabled = false
      skip_confirmation
      skip_reconfirmation!
      save!
      api_key&.destroy!
      follows.destroy_all
      disable_two_factor! if otp_secret_ciphertext.present?
    end
  end

  # Everything stored about the person (GDPR access request), as a JSON-ready hash
  def export_data
    {
      exportedAt: Time.current.iso8601,
      feedbackSpace: tenant.site_name,
      profile: {
        fullName: full_name, email: email, unconfirmedEmail: unconfirmed_email, role: role, status: status,
        notificationsEnabled: notifications_enabled, recapNotificationFrequency: recap_notification_frequency,
        createdAt: created_at&.iso8601, confirmedAt: confirmed_at&.iso8601, signInCount: sign_in_count,
        currentSignInAt: current_sign_in_at&.iso8601, lastSignInAt: last_sign_in_at&.iso8601,
        currentSignInIp: current_sign_in_ip, lastSignInIp: last_sign_in_ip,
        twoFactorEnabled: two_factor_enabled?
      },
      posts: posts.includes(:board, :post_status).order(:created_at).map do |post|
        { id: post.id, title: post.title, description: post.description, board: post.board&.name,
          status: post.post_status&.name, approvalStatus: post.approval_status, createdAt: post.created_at.iso8601 }
      end,
      comments: comments.includes(:post).order(:created_at).map do |comment|
        { id: comment.id, post: comment.post&.title, body: comment.body, isPostUpdate: comment.is_post_update,
          createdAt: comment.created_at.iso8601 }
      end,
      votes: likes.includes(:post).order(:created_at).map { |like| { post: like.post&.title, createdAt: like.created_at.iso8601 } },
      follows: follows.includes(:post).order(:created_at).map { |follow| { post: follow.post&.title, createdAt: follow.created_at.iso8601 } },
      apiKey: api_key && { createdAt: api_key.created_at.iso8601 }
    }
  end

  def full_name_or_email
    if full_name.present? && full_name != I18n.t('defaults.user_full_name') && full_name != I18n.t('defaults.user_full_name', locale: 'en')
      full_name
    else
      email
    end
  end

  def owner?
    role == 'owner'
  end

  def admin?
    owner? || role == 'admin'
  end

  def moderator?
    admin? || role == 'moderator'
  end

  def active?
    status == 'active'
  end

  def blocked?
    status == 'blocked'
  end

  def generate_oauth_token
    self.oauth_token = SecureRandom.urlsafe_base64
    self.save!
    oauth_token
  end

  def invalidate_oauth_token
    self.oauth_token = nil
    self.save!
  end

  private

    def run_webhooks
      entities = {
        user: self.id
      }

      Webhook.where(trigger: :new_user, is_enabled: true).each do |webhook|        
        RunWebhook.perform_later(
          webhook_id: webhook.id,
          current_tenant_id: Current.tenant.id,
          entities: entities
        )
      end
    end
end
