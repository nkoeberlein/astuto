# Users for the moderation list: search by name or email, filter by role and status.
# Fetches one extra row to know whether another page exists.
class ModerationUsersQuery
  PER_PAGE = 50

  Result = Struct.new(:users, :page, :has_more, keyword_init: true)

  def initialize(search: nil, role: nil, status: nil, page: 1, per_page: PER_PAGE)
    @search = search.to_s.strip
    @role = User.roles.key?(role.to_s) ? role.to_s : nil
    @status = User.statuses.key?(status.to_s) ? status.to_s : nil
    @page = [page.to_i, 1].max
    @per_page = per_page
  end

  def call
    rows = scope.offset((@page - 1) * @per_page).limit(@per_page + 1).to_a

    Result.new(users: rows.first(@per_page), page: @page, has_more: rows.size > @per_page)
  end

  private

    def scope
      users = User.all
      users = users.where(role: @role) if @role
      users = users.where(status: @status) if @status
      if @search.present?
        pattern = "%#{User.sanitize_sql_like(@search)}%"
        users = users.where('users.email ILIKE :q OR users.full_name ILIKE :q', q: pattern)
      end
      # Same order as the legacy list: owner and admins first, then newest
      users.order(role: :desc, created_at: :desc, id: :desc)
    end
end
