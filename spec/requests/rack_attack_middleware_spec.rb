require 'rails_helper'

RSpec.describe 'Rack::Attack middleware' do
  it 'runs once per request, after the client IP is known' do
    middlewares = Rails.application.middleware.map(&:klass)

    expect(middlewares.count(Rack::Attack)).to eq(1)
    expect(middlewares.index(Rack::Attack)).to be > middlewares.index(ActionDispatch::RemoteIp)
  end
end
