module BulletTrain
  module Fields
    class Engine < ::Rails::Engine
      initializer "bullet_train.fields" do |app|
        BulletTrain.linked_gems << "bullet_train-fields"
      end
    end
  end
end
