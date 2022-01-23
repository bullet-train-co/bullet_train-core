Rails.application.routes.draw do
  namespace :account do
    shallow do
      resource :two_factor, only: [:create, :destroy]

      # user-level onboarding tasks.
      namespace :onboarding do
        resources :user_details
        resources :user_email
      end

      # user specific resources.
      resources :users

      # team-level resources.
      resources :teams do
        resources :invitations do
          member do
            get :accept
            post :accept
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
