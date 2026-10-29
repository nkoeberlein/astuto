class UserMailer < ApplicationMailer
  def notify_post_owner(comment:)
    Current.tenant = comment.tenant
    @comment = comment
    @user = comment.post.user

    mail(
      to: @user.email,
      subject: t('mailers.user.notify_post_owner.subject', site_name: site_name, post: comment.post.title)
    )
  end

  def notify_comment_owner(comment:)
    Current.tenant = comment.tenant
    @comment = comment
    @user = comment.parent.user

    mail(
      to: @user.email,
      subject: t('mailers.user.notify_comment_owner.subject', site_name: site_name, post: comment.post.title)
    )
  end

  def notify_follower_of_post_update(comment:, follower:)
    Current.tenant = comment.tenant
    @comment = comment
    @user = follower

    mail(
      to: follower.email,
      subject: t('mailers.user.notify_follower_of_post_update.subject', site_name: site_name, post: comment.post.title)
    )
  end

  def notify_follower_of_post_status_change(post:, follower:)
    Current.tenant = post.tenant
    @post = post
    @user = follower

    mail(
      to: follower.email,
      subject: t('mailers.user.notify_follower_of_post_status_change.subject', site_name: site_name, post: post.title)
    )
  end

  # A changelog entry delivers posts the person follows (SaveChangelogEntryWorkflow)
  def notify_follower_of_changelog_entry(user:, entry:)
    Current.tenant = user.tenant
    @user = user
    @entry = entry
    @posts = entry.posts.where(approval_status: 'approved', id: user.follows.select(:post_id)).on_boards_visible_to(user).order(:title).to_a

    mail(
      to: user.email,
      subject: t('mailers.user.notify_follower_of_changelog_entry.subject', site_name: site_name, title: entry.title)
    )
  end

  # frequency: "daily", "weekly" or "monthly"; from/to: the period (see SendRecapEmails)
  def recap(user:, frequency:, from:, to:)
    Current.tenant = user.tenant

    @user = user
    @frequency = t("common.forms.auth.recap_notification_frequency_#{frequency}")
    @digest = RecapDigest.new(user: user, from: from, to: to)

    mail(
      to: user.email,
      subject: t('mailers.user.recap.subject', site_name: site_name, frequency: @frequency)
    )
  end


  private

    def site_name
      Current.tenant_or_raise!.site_name
    end
end