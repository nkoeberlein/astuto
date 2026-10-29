require 'rails_helper'

RSpec.describe 'Health probes and metrics', type: :request do
  describe '/health' do
    it 'answers live, ready and the old check' do
      get '/health/live'
      expect(response).to have_http_status(:ok)

      get '/health/ready'
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq('status' => 'ok', 'checks' => { 'database' => true, 'migrations' => true })

      get '/health'
      expect(response.body).to eq('success')
    end

    it 'reports a failing database as not ready' do
      allow(ActiveRecord::Base).to receive(:connection).and_raise(ActiveRecord::ConnectionNotEstablished)
      get '/health/ready'
      expect(response).to have_http_status(:service_unavailable)
      expect(response.parsed_body.dig('checks', 'database')).to be(false)
    end

    it 'checks Redis when Sidekiq is the job backend' do
      allow(Rails.application).to receive(:sidekiq_enabled?).and_return(true)
      allow(Sidekiq).to receive(:redis).and_raise(RedisClient::CannotConnectError)
      get '/health/ready'
      expect(response).to have_http_status(:service_unavailable)
      expect(response.parsed_body.dig('checks', 'redis')).to be(false)
    end
  end

  describe '/metrics' do
    let(:token) { 'scrape-token' }

    it 'does not exist without METRICS_TOKEN' do
      get '/metrics'
      expect(response).to have_http_status(:not_found)
    end

    context 'with METRICS_TOKEN' do
      before { stub_const('ENV', ENV.to_h.merge('METRICS_TOKEN' => token)) }

      it 'needs the token' do
        get '/metrics', headers: { 'Authorization' => 'Bearer wrong' }
        expect(response).to have_http_status(:unauthorized)
      end

      it 'exports counts per feedback space in the Prometheus text format' do
        FactoryBot.create(:post, approval_status: 'pending')
        FactoryBot.create(:like)

        get '/metrics', headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:ok)
        expect(response.headers['Content-Type']).to start_with('text/plain; version=0.0.4')
        body = response.body
        subdomain = Current.tenant.subdomain
        expect(body).to include(%(astuto_info{version="#{AstutoProject::VERSION}"} 1))
        expect(body).to include('# TYPE astuto_posts gauge')
        expect(body).to match(/^astuto_posts_pending_approval\{tenant="#{subdomain}"\} 1$/)
        expect(body).to match(/^astuto_votes\{tenant="#{subdomain}"\} 1$/)
        expect(body).to include('astuto_webhook_deliveries_last_hour{result="failure"} 0')
      end
    end
  end
end
