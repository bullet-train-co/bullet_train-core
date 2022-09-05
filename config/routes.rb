Rails.application.routes.draw do
  use_doorkeeper

  # See `config/routes.rb` in the starter repository for details.
  collection_actions = [:index, :new, :create] # standard:disable Lint/UselessAssignment
  extending = {only: []}

  namespace :account do
    shallow do
      resources :teams, extending do
        namespace :platform do
          resources :applications do
            resources :access_tokens
          end
        end
      end
    end
  end

  namespace :api do
    namespace :v1 do
      shallow do
        resources :users
        resources :teams do
          resources :invitations
          resources :memberships
          namespace :platform do
            resources :applications do
              resources :access_tokens
            end
          end
        end
      end
    end
  end
end
