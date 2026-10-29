class Post < ApplicationRecord
  include TenantOwnable
  include ApplicationHelper
  include Rails.application.routes.url_helpers
  extend FriendlyId
  
  belongs_to :board
  belongs_to :user, optional: true
  belongs_to :post_status, optional: true

  has_many :likes, dependent: :destroy
  has_many :follows, dependent: :destroy
  has_many :followers, through: :follows, source: :user
  has_many :comments, dependent: :destroy
  has_many :post_status_changes, dependent: :destroy
  has_many :changelog_entry_posts, dependent: :delete_all
  has_many :changelog_entries, through: :changelog_entry_posts

  after_create :run_new_post_webhooks
  after_destroy :run_delete_post_webhooks

  enum :approval_status, [
    :approved,
    :pending,
    :rejected,
    # Merged into another post (merged_into), see MergePostsWorkflow
    :merged
  ]

  belongs_to :merged_into, class_name: 'Post', foreign_key: :merged_into_post_id, optional: true
  # Merged duplicates are empty shells that redirect here; they go with this post
  has_many :merged_posts, class_name: 'Post', foreign_key: :merged_into_post_id, dependent: :destroy, inverse_of: :merged_into

  validates :title, presence: true, length: { in: 4..128 }
  validates :source_label, length: { maximum: 40 }
  validates :source_url, length: { maximum: 500 }
  validate :source_url_is_a_link

  # Moderators link to where feedback came from (Slack, email, ticket): http(s) or mailto only
  def source_url_is_a_link
    return if source_url.blank?
    return if SafeUrl.safe?(source_url) && !SafeUrl.local_path?(source_url)

    errors.add(:source_url, :invalid)
  end

  paginates_per Rails.application.posts_per_page

  friendly_id :title, use: :scoped, scope: :tenant_id

  def url
    get_url_for(method(:post_url), resource: self)
  end

  class << self
    def find_with_post_status_in(post_statuses)
      where(post_status_id: post_statuses.pluck(:id))
    end

    def search_by_name_or_description(s)
      query = s.to_s.strip
      return all if query.blank?

      like_pattern = "%#{sanitize_sql_like(query)}%"
      ts_vector = "to_tsvector('simple', coalesce(posts.title, '') || ' ' || coalesce(posts.description, ''))"
      where(
        "#{ts_vector} @@ websearch_to_tsquery('simple', :q) OR posts.title ILIKE :like OR coalesce(posts.description, '') ILIKE :like",
        q: query,
        like: like_pattern
      )
    end

    # Finds potential duplicate posts using PostgreSQL full-text search (tsvector + ts_rank)
    # across title and description, matching any significant token (>= 3 chars) and ranking
    # posts that match more tokens higher.
    def similar_to(text, board_id: nil, limit: 5)
      tokens = text.to_s.scan(/[[:alnum:]]{3,}/).map(&:downcase).uniq.first(10)
      return none if tokens.empty?

      ts_query_str = tokens.map { |t| "#{t}:*" }.join(' | ')
      ts_vector_sql = "to_tsvector('simple', coalesce(posts.title, '') || ' ' || coalesce(posts.description, ''))"
      ts_query_sql = sanitize_sql_array(["to_tsquery('simple', ?)", ts_query_str])
      rank_sql = Arel.sql("ts_rank(#{ts_vector_sql}, #{ts_query_sql}) DESC, posts.created_at DESC")

      scope = where(approval_status: 'approved')
      scope = scope.where(board_id: board_id) if board_id.present?
      scope
        .where("#{ts_vector_sql} @@ to_tsquery('simple', ?)", ts_query_str)
        .order(rank_sql)
        .limit(limit)
    end

    def order_by(sort_by)
      case sort_by
      when 'newest'
        order(created_at: :desc)
      when 'trending'
        order(hotness: :desc)
      when 'most_voted'
        order(likes_count: :desc)
      when 'oldest'
        order(created_at: :asc)
      else
        order(created_at: :desc)
      end
    end

    def pending
      where(approval_status: "pending")
    end
  end

  private

    def run_new_post_webhooks
      entities = {
        post: self.id,
        board: self.board.id
      }
      entities[:post_author] = self.user.id if self.user_id

      # New post (approved)
      if self.approval_status == 'approved'
        Webhook.where(trigger: :new_post, is_enabled: true).each do |webhook|        
          RunWebhook.perform_later(
            webhook_id: webhook.id,
            current_tenant_id: Current.tenant.id,
            entities: entities
          )
        end
      end

      # New post (pending approval)
      if self.approval_status == 'pending'
        Webhook.where(trigger: :new_post_pending_approval, is_enabled: true).each do |webhook|
          RunWebhook.perform_later(
            webhook_id: webhook.id,
            current_tenant_id: Current.tenant.id,
            entities: entities
          )
        end
      end
    end

    def run_delete_post_webhooks
      # Since the post has already been deleted from DB
      # we only provide its ID
      entities = { post_id: self.id }

      Webhook.where(trigger: :delete_post, is_enabled: true).each do |webhook|
        RunWebhook.perform_later(
          webhook_id: webhook.id,
          current_tenant_id: Current.tenant.id,
          entities: entities
        )
      end
    end
end
