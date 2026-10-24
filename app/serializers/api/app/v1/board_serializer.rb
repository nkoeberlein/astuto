module Api::App::V1
  module BoardSerializer
    def self.call(board)
      { id: board.id, name: board.name, slug: board.slug, description: board.description }
    end
  end
end
