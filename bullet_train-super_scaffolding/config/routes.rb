Rails.application.routes.draw do
  # See `config/routes.rb` for details.
  collection_actions = [:index, :new, :create]
  extending = {only: []}

  namespace :api do
    namespace :v1 do
      shallow do
        model "Team", extending do
          unless scaffolding_things_disabled?
            model "Scaffolding::AbsolutelyAbstract::CreativeConcept" do
              model "Scaffolding::CompletelyConcrete::TangibleThing"
            end
          end
        end
      end
    end
  end

  namespace :account do
    shallow do
      model "Team" do
        unless scaffolding_things_disabled?
          model "Scaffolding::AbsolutelyAbstract::CreativeConcept" do
            model "Scaffolding::CompletelyConcrete::TangibleThing"
          end
        end
      end
    end
  end
end
