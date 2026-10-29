module Api::App::V1
  # Public view of a user as author of posts and comments.
  # Never includes the email address (the legacy JSON endpoints leak it).
  module AuthorSerializer
    def self.call(user)
      return nil if user.nil?

      {
        id: user.id,
        fullName: user.full_name.presence || I18n.t('defaults.user_full_name'),
        avatarUrl: user.avatar_url
      }
    end
  end
end
