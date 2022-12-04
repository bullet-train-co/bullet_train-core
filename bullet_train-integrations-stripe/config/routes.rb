Rails.application.routes.draw do
  namespace :webhooks do
    namespace :incoming do
      namespace :oauth do
        resources :stripe_account_webhooks
      end
    end
  end

  namespace :account do
    shallow do
      # user specific resources.
      resources :users do
        namespace :oauth do
          resources :stripe_accounts
        end
      end

      resources :teams do
        namespace :integrations do
          resources :stripe_installations
        end
      end
    end
  end
end
