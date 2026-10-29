Rails.application.routes.draw do
  if !Rails.application.multi_tenancy?
    mount Rswag::Api::Engine => '/api-docs'
  end

  if Rails.application.multi_tenancy?
    constraints subdomain: 'api' do
      mount Rswag::Api::Engine => '/api-docs'
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
    get '/embed', to: 'spa#show', as: :embed
    get '/boards/:id', to: 'spa#show', format: false, as: :board
    get '/boards/:id/feed', to: 'feeds#board', format: false, as: :board_feed
    get '/changelog', to: 'spa#show', as: :changelog
    get '/changelog/feed', to: 'feeds#changelog', format: false, as: :changelog_feed
    get '/robots.txt', to: 'seo#robots', format: false, as: :robots
    get '/sitemap.xml', to: 'seo#sitemap', format: false, as: :sitemap
    get '/posts/:id', to: 'spa#show', format: false, as: :post
    get '/login', to: 'spa#show', as: :spa_login
    get '/register', to: 'spa#show', as: :spa_register
    get '/password/forgot', to: 'spa#show', as: :spa_password_forgot
    get '/password/reset', to: 'spa#show', as: :spa_password_reset
    get '/confirmation/new', to: 'spa#show', as: :spa_confirmation_new
    get '/unlock/new', to: 'spa#show', as: :spa_unlock_new
    get '/profile', to: 'spa#show', as: :spa_profile
    get '/my-feedback', to: 'spa#show', as: :spa_my_feedback
    %w[feedback users].each do |section|
      get "/moderation/#{section}", to: 'spa#show', as: "moderation_#{section}"
    end
    %w[general authentication boards post_statuses tags roadmap webhooks widget invitations appearance audit_log].each do |section|
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
    
    # SAML single sign-on (docs/sso.md)
    get '/saml/metadata', to: 'saml#metadata', as: :saml_metadata
    get '/saml/start', to: 'saml#start', as: :saml_start
    post '/saml/acs', to: 'saml#acs', as: :saml_acs
    get '/saml/finish', to: 'saml#finish', as: :saml_finish

    get '/o_auths/:id/start', to: 'o_auths#start', as: :o_auth_start
    get '/o_auths/:id/callback', to: 'o_auths#callback', as: :o_auth_callback
    get '/o_auths/sign_in_from_oauth_token', to: 'o_auths#sign_in_from_oauth_token', as: :o_auth_sign_in_from_oauth_token

    # API routes
    # JSON API for the v2 frontend (frontend/), session cookie + CSRF header
    namespace :api do
      namespace :app do
        namespace :v1 do
          resource :session, only: [:show, :create, :destroy] do
            post :two_factor
            post :ldap
          end
          resource :registration, only: [:create]
          resource :password, only: [:create, :update]
          resource :confirmation, only: [:create]
          resource :unlock, only: [:create]
          resource :profile, only: [:show, :update, :destroy] do
            post :api_key
            get :export
            resource :two_factor, only: [:create, :destroy], controller: 'two_factors' do
              post :confirm
              post :backup_codes
            end
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
          resources :my_posts, only: [:index]
          resources :tags, only: [:index, :create, :update, :destroy] do
            put :reorder, on: :collection
          end
          post 'widget/session', to: 'widget_sessions#create'
          resources :changelog_entries, only: [:index, :create, :update, :destroy] do
            get :linkable_posts, on: :collection
            post :draft, on: :collection
          end
          resources :posts, only: [:show, :update, :destroy] do
            post :merge, on: :member
            resources :comments, only: [:index, :create, :update, :destroy] do
              post :translation, to: 'feedback_translations#translate_comment'
            end
            resource :vote, only: [:create, :destroy]
            resource :follow, only: [:create, :destroy]
            resource :summary, only: [:create]
            post :translation, to: 'feedback_translations#translate_post'
          end
          namespace :moderation do
            resources :posts, only: [:index]
            resources :users, only: [:index, :update, :destroy] do
              get :export, on: :member
            end
          end
          namespace :site_settings do
            resource :general, only: [:show, :update], controller: 'general'
            resource :test_email, only: [:create]
            resources :o_auths, only: [:index, :create, :update, :destroy] do
              put :default, on: :member
            end
            resources :webhooks, only: [:index, :create, :update, :destroy] do
              get :variables, on: :collection
              get :templates, on: :collection
              post :preview, on: :collection
              post :test, on: :member
              get :deliveries, on: :member
              post :rotate_secret, on: :member
            end
            resources :invitations, only: [:index, :create] do
              post :test, on: :collection
            end
            resources :audit_events, only: [:index]
            resource :saml, only: [:show, :update], controller: 'saml' do
              post :parse_metadata
            end
            resource :ldap, only: [:show, :update], controller: 'ldap' do
              post :test
            end
            resource :widget, only: [:show, :update], controller: 'widget' do
              post :rotate_secret
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

  # Probes and metrics (docs/operations.md)
  get '/health', to: 'health#show'
  get '/health/live', to: 'health#live'
  get '/health/ready', to: 'health#ready'
  get '/metrics', to: 'metrics#show'
end
