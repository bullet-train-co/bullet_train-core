Rails.application.routes.draw do
  unless Rails.env.production?
    mount Showcase::Engine, at: "/docs/showcase" if defined?(Showcase::Engine)
  end

  scope module: "public" do
    root to: "home#index"
    get "invitation" => "home#invitation", :as => "invitation"

    if Rails.env.development?
      get "docs", to: "home#docs"
      get "docs/*page", to: "home#docs"
    end
  end

  namespace :account do
    shallow do
      # TODO we need to either implement a dashboard or deprecate this.
      root to: "dashboard#index", as: "dashboard"

      resource :two_factor, only: [:create, :destroy] do
        post :verify
      end

      # user-level onboarding tasks.
      namespace :onboarding do
        resources :user_details
        resources :user_email
        resources :invitation_lists, only: [:new, :create]
      end

      # user specific resources.
      resources :users

      # team-level resources.
      resources :teams do
        resources :invitations do
          member do
            get :accept
            post :accept
            post :resend
          end
        end

        resources :memberships do
          member do
            post :demote
            post :promote
            post :reinvite
          end

          collection do
            get :search
          end
        end

        member do
          post :switch_to
        end
      end
    end
  end
end
