require 'rails_helper'

RSpec.describe 'posts routing', :aggregate_failures, type: :routing do
  it 'serves post pages from the frontend; the old JSON endpoints are gone' do
    expect(get: '/posts/1').to route_to(controller: 'spa', action: 'show', id: '1')
    expect(get: '/posts').not_to be_routable
    expect(post: '/posts').not_to be_routable
    expect(get: '/posts/1/comments').not_to be_routable
    expect(post: '/posts/1/likes').not_to be_routable
    expect(delete: '/posts/1').not_to be_routable
  end
end
