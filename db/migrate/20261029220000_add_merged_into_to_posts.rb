# Merged duplicates: the post keeps its URL and redirects to the post it was merged into, whose
# votes, followers and comments it took over. approval_status 3 ("merged") hides it from lists.
class AddMergedIntoToPosts < ActiveRecord::Migration[8.1]
  def change
    add_reference :posts, :merged_into_post, foreign_key: { to_table: :posts }, index: true
  end
end
