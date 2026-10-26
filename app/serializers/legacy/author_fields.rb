module Legacy
  # Author fields for the legacy UI's JSON (comments, likes, status changes, posts).
  # Email addresses are personal data: only moderators and the person themselves
  # see them. Everyone gets the Gravatar hash, so avatars keep working.
  module AuthorFields
    def self.call(viewer:, user_id:, email:, prefix: 'user_')
      visible = viewer.present? && (viewer.moderator? || viewer.id == user_id)
      {
        "#{prefix}email" => visible ? email : nil,
        "#{prefix}gravatar_hash" => User.gravatar_hash(email)
      }
    end

    # Merges the author fields into a record's JSON. The record must have
    # selected the author's email (as `email_attribute`) and `user_id`.
    def self.merge(record, viewer:, email_attribute: :user_email, prefix: 'user_')
      email = record[email_attribute]
      record.as_json
        .except(email_attribute.to_s)
        .merge(call(viewer: viewer, user_id: record[:user_id], email: email, prefix: prefix))
    end
  end
end
