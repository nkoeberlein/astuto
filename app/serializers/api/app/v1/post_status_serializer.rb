module Api::App::V1
  module PostStatusSerializer
    def self.call(post_status)
      {
        id: post_status.id,
        name: post_status.name,
        color: post_status.color,
        order: post_status.order,
        showInRoadmap: post_status.show_in_roadmap
      }
    end
  end
end
