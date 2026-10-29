module Api::App::V1
  module TagSerializer
    def self.call(tag)
      { id: tag.id, name: tag.name, color: tag.color, order: tag.order }
    end
  end
end
