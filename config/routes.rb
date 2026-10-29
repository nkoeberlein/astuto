Rails.application.routes.draw do
  if !Rails.application.multi_tenancy?
    mount Rswag::Api::Engine => '/api-docs'
  end

  if Rails.application.multi_tenancy?
    constraints subdomain: 'api' do
      mount Rswag::Api::Engine => '/api-docs'
    end

    constraints subdomain: 'login' do
      get '/signup', to: 'tenants#new'
      get '/is_available', to: 'tenants#is_available'
      
      resource :tenants, only: [:create]
    end
  end

  # Instance admin (multi-tenancy, INSTANCE_ADMIN_PASSWORD, BASE_URL host only; docs/multi-tenancy.md)
  namespace :instance_admin, path: 'instance' do
    root to: redirect('/instance/tenants')
    resources :tenants, except: [:show] do
      member do
        put :block
        put :unblock
      end
    end
  end

  constraints subdomain: /.*/ do
    # Pages of the v2 frontend (frontend/ → public/next), served by SpaController.
    # Named routes keep URL helpers in mails and workflows (root_url, roadmap_url, post_url, ...).
    root to: 'spa#show'
    get '/roadmap', to: 'spa#show', as: :roadmap
    get '/embedded_roadmap', to: 'spa#show', as: :embedded_roadmap
    get '/boards/:id', to: 'spa#show', format: false
    get '/posts/:id', to: 'spa#show', format: false
    get '/login', to: 'spa#show', as: :spa_login
    get '/register', to: 'spa#show', as: :spa_register
    get '/password/forgot', to: 'spa#show', as: :spa_password_forgot
    get '/password/reset', to: 'spa#show', as: :spa_password_reset
    get '/confirmation/new', to: 'spa#show', as: :spa_confirmation_new
    get '/unlock/new', to: 'spa#show', as: :spa_unlock_new
    get '/profile', to: 'spa#show', as: :spa_profile
    %w[feedback users].each do |section|
      get "/moderation/#{section}", to: 'spa#show', as: "moderation_#{section}"
    end
    %w[general authentication boards post_statuses roadmap webhooks invitations appearance].each do |section|
      get "/site_settings/#{section}", to: 'spa#show', as: "site_settings_#{section}"
    end
    # The v2 frontend lived under /next until 2.0; old links and embed codes keep working
    get '/next(/*path)', format: false, to: redirect(status: 301) { |params, request|
      query = request.query_string.presence
      "/#{params[:path]}#{"?#{query}" if query}"
    }

    get '/pending-tenant', to: 'static_pages#pending_tenant'
    get '/blocked-tenant', to: 'static_pages#blocked_tenant'
    
    devise_for :users, :controllers => {
      :registrations => 'registrations',
      :sessions => 'sessions',
      :passwords => 'passwords',
      :confirmations => 'confirmations',
      :unlocks => 'unlocks'
    }

    devise_scope :user do
      get '/users/send_set_password_instructions', to: 'registrations#send_set_password_instructions', as: :send_set_password_instructions
    end
    
    resources :tenants, only: [:show, :update]
    resources :users, only: [:index, :update]
    resources :webhooks, only: [:index, :create, :update, :destroy]
    put '/webhooks_preview', to: 'webhooks#preview'
    put '/webhooks/:id/test', to: 'webhooks#test'
    resources :o_auths, only: [:index, :create, :update, :destroy] do
      resource :tenant_default_o_auths, only: [:create, :destroy]
    end
    get '/o_auths/:id/start', to: 'o_auths#start', as: :o_auth_start
    get '/o_auths/:id/callback', to: 'o_auths#callback', as: :o_auth_callback
    get '/o_auths/sign_in_from_oauth_token', to: 'o_auths#sign_in_from_oauth_token', as: :o_auth_sign_in_from_oauth_token
  
    resources :posts, only: [:index, :create, :update, :destroy] do
      resource :follows, only: [:create, :destroy]
      resources :follows, only: [:index]
      resource :likes, only: [:create, :destroy]
      resources :likes, only: [:index]
      resources :comments, only: [:index, :create, :update, :destroy]
      resources :post_status_changes, only: [:index]

      get '/moderation', on: :collection, to: 'posts#moderation'
    end
    
    resources :boards, only: [:index, :create, :update, :destroy] do
      patch 'update_order', on: :collection
    end
  
    resources :post_statuses, only: [:index, :create, :update, :destroy] do
      patch 'update_order', on: :collection
    end

    resources :invitations, only: [:create]
    post '/invitations/test', to: 'invitations#test', as: :invitation_test

    resources :api_keys, only: [:create]
  
    # API routes
    # JSON API for the v2 frontend (frontend/), session cookie + CSRF header
    namespace :api do
      namespace :app do
        namespace :v1 do
          resource :session, only: [:show, :create, :destroy]
          resource :registration, only: [:create]
          resource :password, only: [:create, :update]
          resource :confirmation, only: [:create]
          resource :unlock, only: [:create]
          resource :profile, only: [:show, :update, :destroy] do
            post :api_key
          end
          resources :translations, only: [:show], param: :locale, constraints: { locale: /[A-Za-z-]+/ }
          resources :boards, only: [:index, :show, :create, :update, :destroy] do
            put :reorder, on: :collection
            resources :posts, only: [:index, :create]
          end
          resources :post_statuses, only: [:index, :create, :update, :destroy] do
            put :reorder, on: :collection
          end
          resource :roadmap, only: [:show]
          resources :posts, only: [:show, :update, :destroy] do
            resources :comments, only: [:index, :create, :update, :destroy]
            resource :vote, only: [:create, :destroy]
            resource :follow, only: [:create, :destroy]
            resource :summary, only: [:create]
          end
          namespace :moderation do
            resources :posts, only: [:index]
            resources :users, only: [:index, :update]
          end
          namespace :site_settings do
            resource :general, only: [:show, :update], controller: 'general'
            resource :test_email, only: [:create]
            resources :o_auths, only: [:index, :create, :update, :destroy] do
              put :default, on: :member
            end
            resources :webhooks, only: [:index, :create, :update, :destroy] do
              get :variables, on: :collection
              post :preview, on: :collection
              post :test, on: :member
              get :deliveries, on: :member
              post :rotate_secret, on: :member
            end
            resources :invitations, only: [:index, :create] do
              post :test, on: :collection
            end
          end
        end
      end
    end

    # Model Context Protocol (MCP) Streamable HTTP endpoint (authenticated via API key)
    post '/mcp', to: 'mcp#handle'
    get '/mcp', to: 'mcp#handle'
    delete '/mcp', to: 'mcp#handle'

    namespace :api do
      namespace :v1 do
        resources :boards, only: [:index, :show, :create]
        resources :post_statuses, only: [:index]
        resources :posts, only: [:index, :show, :create, :update, :destroy] do
          member do
            put :update_board
            put :update_status
            put :approve
            put :reject
          end
        end
        resources :comments, only: [:index, :show, :create, :update, :destroy] do
          member do
            put :mark_as_post_update
            put :unmark_as_post_update
          end
        end
        resources :votes, only: [:index, :show, :create, :destroy], controller: 'likes'
        resources :users, only: [:index, :show, :create] do
          collection do
            get :get_by_email, controller: 'users', action: 'show_by_email'
          end
          member do
            put :block
          end
        end 
      end
    end
  end

  # Caddy on-demand TLS asks here before it requests a certificate (docs/multi-tenancy.md)
  get '/custom_domain_check', to: 'custom_domain_checks#show'

  # Healthcheck endpoint
  get '/health', to: proc {
    Tenant.first # to make sure db works
    [200, {}, ['success']]
  }
end
