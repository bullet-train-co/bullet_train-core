Rails.application.routes.draw do
  use_doorkeeper

  namespace :api do
    namespace :v1 do
      shallow do
        resources :users
        resources :teams do
          resources :invitations
          resources :memberships
          namespace :platform do
            resources :applications
          end
        end
      end
    end
  end
end
