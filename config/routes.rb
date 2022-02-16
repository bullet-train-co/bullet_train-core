Rails.application.routes.draw do
  namespace :account do
    shallow do
      resources :teams do
        namespace :webhooks do
          namespace :outgoing do
            resources :events
            resources :endpoints do
              resources :deliveries, only: [:index, :show] do
                resources :delivery_attempts, only: [:index, :show]
              end
            end
          end
        end
      end
    end
  end
end
