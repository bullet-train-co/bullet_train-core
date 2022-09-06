Rails.application.routes.draw do
  # See `config/routes.rb` for details.
  collection_actions = [:index, :new, :create]
  extending = {only: []}

  namespace :api do
    namespace :v1 do
      shallow do
        resources :teams, extending do
          unless scaffolding_things_disabled?
            namespace :scaffolding do
              namespace :absolutely_abstract do
                resources :creative_concepts do
                  scope module: "creative_concepts" do
                    resources :collaborators, only: collection_actions
                  end

                  namespace :creative_concepts do
                    resources :collaborators, except: collection_actions
                  end
                end
              end
              resources :absolutely_abstract_creative_concepts, path: "absolutely_abstract/creative_concepts" do
                namespace :completely_concrete do
                  resources :tangible_things
                end
              end
            end
          end
        end
      end
    end
  end

  namespace :account do
    shallow do
      resources :teams do
        unless scaffolding_things_disabled?
          namespace :scaffolding do
            namespace :absolutely_abstract do
              resources :creative_concepts do
                scope module: "creative_concepts" do
                  resources :collaborators, only: collection_actions
                end

                namespace :creative_concepts do
                  resources :collaborators, except: collection_actions
                end
              end
            end
            resources :absolutely_abstract_creative_concepts, path: "absolutely_abstract/creative_concepts" do
              namespace :completely_concrete do
                resources :tangible_things
              end
            end
          end
        end
      end
    end
  end
end
