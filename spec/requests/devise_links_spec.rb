require 'rails_helper'

# Confirmation and unlock links in emails keep working; their pages live in the v2 frontend
RSpec.describe 'Devise confirmation and unlock links', type: :request do
  it 'sends the old request pages to the v2 pages' do
    get '/users/confirmation/new'
    expect(response).to redirect_to('/confirmation/new')
    get '/users/unlock/new'
    expect(response).to redirect_to('/unlock/new')
  end

  it 'serves the v2 pages' do
    get '/confirmation/new'
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(I18n.t('common.forms.auth.resend_confirmation_instructions'))
    get '/unlock/new'
    expect(response).to have_http_status(:ok)
  end

  it 'confirms an account and continues to the login page' do
    user = FactoryBot.create(:user, confirmed_at: nil)
    token = user.confirmation_token

    get '/users/confirmation', params: { confirmation_token: token }
    expect(user.reload).to be_confirmed
    expect(response).to have_http_status(:redirect)
    follow_redirect!
    follow_redirect! if response.redirect?
    expect(response.body).to include(I18n.t('devise.confirmations.confirmed'))
  end

  it 'sends an invalid confirmation link to the v2 page with the error' do
    get '/users/confirmation', params: { confirmation_token: 'wrong' }
    expect(response).to redirect_to('/confirmation/new')
    expect(flash[:alert]).to be_present
  end

  it 'unlocks an account and sends an invalid link to the v2 page' do
    user = FactoryBot.create(:user).tap(&:confirm)
    user.lock_access!(send_instructions: false)
    raw, encrypted = Devise.token_generator.generate(User, :unlock_token)
    user.update_column(:unlock_token, encrypted)

    get '/users/unlock', params: { unlock_token: raw }
    expect(user.reload).not_to be_access_locked
    expect(response).to have_http_status(:redirect)

    get '/users/unlock', params: { unlock_token: 'wrong' }
    expect(response).to redirect_to('/unlock/new')
    expect(flash[:alert]).to be_present
  end
end
