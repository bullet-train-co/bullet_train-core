module BulletTrain
  module Fields
    class Engine < ::Rails::Engine
      initializer "bullet_train.fields" do |app|
        # Older versions of Bullet Train have a `BulletTrain` module, but it doesn't have `linked_gems`.
        if BulletTrain.respond_to?(:linked_gems)
          BulletTrain.linked_gems << "bullet_train-fields"
        end
      end
    end
  end
end
