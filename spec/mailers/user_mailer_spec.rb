require "rails_helper"

RSpec.describe UserMailer, type: :mailer do
  describe "notify_comment" do
    let(:user) { FactoryBot.create(:user, email: "notified@example.com", notifications_enabled: true) }
    let(:post) { FactoryBot.create(:post, user: user)}
    let(:comment) { FactoryBot.create(:comment, post: post) }
    let(:mail) { UserMailer.notify_post_owner(comment: comment) }

    it "renders the headers" do
      expect(mail.to).to eq([user.email])
      # BASE_URL of the test env is http://localhost:3000; without EMAIL_MAIL_FROM the sender is noreply@<host>
      expect(mail.from).to eq([Rails.application.default_mail_from])
    end

    it "renders the post title, replier name and comment body" do
      expect(mail.body.encoded).to include(post.title)
      expect(mail.body.encoded).to include(comment.user.full_name)
      expect(mail.body.encoded).to include(comment.body)
    end
  end

  describe "recap" do
    let(:user) { FactoryBot.create(:user, email: "digest@example.com") }

    it "shows new feedback, the most voted posts and status changes of followed posts" do
      followed = FactoryBot.create(:post, title: "Dark mode")
      Follow.create!(user: user, post: followed)
      PostStatusChange.create!(post: followed, user: FactoryBot.create(:moderator), post_status: FactoryBot.create(:post_status, name: "Planned"))
      FactoryBot.create(:like, post: followed)

      mail = UserMailer.recap(user: user, frequency: "weekly", from: 1.week.ago, to: 1.minute.from_now)
      body = mail.body.encoded

      expect(mail.subject).to include("Weekly")
      expect(body).to include("Status changes of posts you follow", "Planned", "/posts/#{followed.slug}")
      expect(body).to include("New published feedback: 1", "Most voted in this period", "1 new vote")
      expect(body).not_to include("pending approval")
    end

    it "shows moderators the feedback waiting for approval" do
      FactoryBot.create(:post, approval_status: "pending")
      mail = UserMailer.recap(user: FactoryBot.create(:moderator), frequency: "daily", from: 1.day.ago, to: 1.minute.from_now)

      expect(mail.body.encoded).to include("New feedback pending approval: 1", "/moderation/feedback")
    end
  end
end
