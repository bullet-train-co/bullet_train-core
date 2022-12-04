module BulletTrain
  module Sortable
    class Engine < ::Rails::Engine
      initializer "bullet_train.sortable.register_routing_concerns" do |app|
        BulletTrain.routing_concerns << proc do
          concern :sortable do
            collection do
              post :reorder
            end
          end
        end
      end
    end
  end
end
