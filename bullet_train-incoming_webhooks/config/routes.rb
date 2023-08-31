Rails.application.routes.draw do
  namespace :webhooks do
    namespace :incoming do
      resources :bullet_train_webhooks
    end
  end
end
