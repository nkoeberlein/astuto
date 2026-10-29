require 'rails_helper'

RSpec.describe 'boards routing', :aggregate_failures, type: :routing do
  it 'serves board pages from the frontend; boards data comes from the app API' do
    expect(get: '/boards/1').to route_to(controller: 'spa', action: 'show', id: '1')
    expect(get: '/api/app/v1/boards').to route_to(controller: 'api/app/v1/boards', action: 'index')
    expect(get: '/boards').not_to be_routable
    expect(post: '/boards').not_to be_routable
    expect(patch: '/boards/1').not_to be_routable
  end
end
