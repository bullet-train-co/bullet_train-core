Rails.application.routes.draw do
  extending = {only: []}

  namespace :account do
    shallow do
      model BulletTrain::OutgoingWebhooks.parent_class do
        model "Webhooks::Outgoing::Endpoint" do
          member do
            post :activate
            delete :deactivate
          end

          model "Webhooks::Outgoing::Delivery", only: %i[index show] do
            model "Webhooks::Outgoing::DeliveryAttempt", only: %i[index show]
          end

          member do
            post :rotate_secret
          end
        end
      end
    end
  end

  namespace :api do
    namespace :v1 do
      shallow do
        model "Team", extending do
          model "Webhooks::Outgoing::Endpoint", defaults: {format: :json}
          model "Webhooks::Outgoing::Event", only: %i[index show], defaults: {format: :json}
        end
      end
    end
  end
end
