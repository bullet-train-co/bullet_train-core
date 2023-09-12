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

  get "/testing/provision", to: "account/platform/applications#provision"

  namespace :api do
    match "*version/openapi.yaml" => "open_api#index", :via => :get

    BulletTrain::Api.all_versions.each do |version|
      namespace version do
        shallow do
          resources :users
          resources :teams do
            resources :invitations do
              member do
                post :resend
              end
            end
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
end
