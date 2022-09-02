module BulletTrain
  module SuperScaffolding
    class Engine < ::Rails::Engine
      initializer "bullet_train.super_scaffolding.register_template_path" do |app|
        # Templates from the application itself should always be highest priority.
        # This allows application developers to locally overload any template from any package.
        BulletTrain::SuperScaffolding.template_paths << Rails.root.to_s

        # Register the base path of this package with the Super Scaffolding engine.
        BulletTrain::SuperScaffolding.template_paths << File.expand_path("../../../..", __FILE__)
      end

      initializer "bullet_train.super_scaffolding.register" do |app|
        # Older versions of Bullet Train have a `BulletTrain` module, but it doesn't have `linked_gems`.
        if BulletTrain.respond_to?(:linked_gems)
          BulletTrain.linked_gems << "bullet_train-super_scaffolding"
        end
      end
    end
  end
end
