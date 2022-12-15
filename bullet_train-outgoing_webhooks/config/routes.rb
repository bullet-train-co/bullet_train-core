Rails.application.routes.draw do
  extending = {only: []}

  namespace :account do
    shallow do
      resources BulletTrain::OutgoingWebhooks.parent_resource do
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

  namespace :api do
    namespace :v1 do
      shallow do
        resources :teams, extending do
          namespace :webhooks do
            namespace :outgoing do
              resources :endpoints, defaults: {format: :json}
            end
          end
        end
      end
    end
  end
end
