# Private boards (#414): who can see a board and its posts
class AddVisibilityToBoards < ActiveRecord::Migration[8.1]
  def change
    add_column :boards, :visibility, :integer, null: false, default: 0
  end
end
