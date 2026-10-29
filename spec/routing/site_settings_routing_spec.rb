require 'rails_helper'

# The site settings pages are part of the v2 frontend
RSpec.describe 'site settings routing', :aggregate_failures, type: :routing do
  it 'routes every section to the SPA' do
    %w[general authentication boards post_statuses roadmap webhooks invitations appearance].each do |section|
      expect(get: "/site_settings/#{section}").to route_to(controller: 'spa', action: 'show')
    end
  end
end
