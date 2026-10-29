require 'rails_helper'

# The moderation pages are part of the v2 frontend
RSpec.describe 'moderation routing', :aggregate_failures, type: :routing do
  it 'routes the moderation pages to the SPA' do
    %w[/moderation/feedback /moderation/users].each do |path|
      expect(get: path).to route_to(controller: 'spa', action: 'show')
    end
  end
end
