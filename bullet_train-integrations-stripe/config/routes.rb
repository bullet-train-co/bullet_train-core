Rails.application.routes.draw do
  model "Webhooks::Incoming::Oauth::StripeAccountWebhook"

  namespace :account do
    shallow do
      # user specific resources.
      model "User" do
        model "Oauth::StripeAccount"
      end

      model "Team" do
        model "Integrations::StripeInstallation"
      end
    end
  end
end
