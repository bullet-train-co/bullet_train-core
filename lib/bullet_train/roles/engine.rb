module BulletTrain
  module Roles
    class Engine < ::Rails::Engine
      config.eager_load_paths << Role.full_path

      initializer "bullet_train-roles.config" do |app|
        role_reloader = ActiveSupport::FileUpdateChecker.new([Role.full_path]) do
          Role.reload(true)
        end

        ActiveSupport::Reloader.to_prepare do
          role_reloader.execute_if_updated
        end
      end
    end
  end
end
