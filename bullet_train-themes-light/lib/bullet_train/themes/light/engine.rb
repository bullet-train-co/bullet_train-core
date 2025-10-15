module BulletTrain
  module Themes
    module Light
      class Engine < ::Rails::Engine
        initializer "bullet_train.themes.light.register" do |app|
          BulletTrain::Themes.themes[:light] = BulletTrain::Themes::Light::Theme.new
          if BulletTrain.respond_to?(:linked_gems)
            BulletTrain.linked_gems << "bullet_train-themes-light"
          end
        end

        initializer "bullet_train.themes.light.check_tailwind_config", after: :load_config_initializers do |app|
          # Only check in development and test (including CI) to avoid spamming production logs
          next if Rails.env.production?

          Rails.application.config.after_initialize do
            tailwind_config_path = Rails.root.join("tailwind.config.js")

            if tailwind_config_path.exist?
              config_content = tailwind_config_path.read

              # Check for darkMode configuration with 'class' or 'selector'
              if config_content.match?(/darkMode\s*[=:]\s*['"](?:class|selector)['"]/) ||
                  config_content.match?(/themeConfig\.darkMode\s*=\s*['"](?:class|selector)['"]/)

                Rails.logger.warn <<~WARNING
 
                  ------------------------------------------------------------
                  
                  ⚠️  DEPRECATION WARNING: Dark mode configuration in tailwind.config.js
                  
                  Your tailwind.config.js file contains a darkMode setting using 'class' or 'selector'.
                  This is now the default setting for Bullet Train, allowing users to choose their preference in Account Details.
                  
                  If you want to force light mode for all users, use the force_color_scheme_to option in config/initializers/theme.rb:
                  
                    BulletTrain::Themes::Light.force_color_scheme_to = :light  # or :dark
                  
                  You can then remove the darkMode configuration from tailwind.config.js.
 
                  ------------------------------------------------------------
                  
                WARNING
              # Check for darkMode configuration with 'media'
              elsif config_content.match?(/darkMode\s*[=:]\s*['"]media['"]/) ||
                  config_content.match?(/themeConfig\.darkMode\s*=\s*['"]media['"]/)

                Rails.logger.warn <<~WARNING
 
                  ------------------------------------------------------------
                  
                  ℹ️  NOTICE: Dark mode configuration in tailwind.config.js
                  
                  Your tailwind.config.js file contains a darkMode setting using 'media'.
                  This setting is safe to remove, as Bullet Train now handles color scheme preferences automatically.
                  
                  Users can choose their preferred color scheme in Account Details, which respects their system preference by default.
                  
                  If you want to force a specific color scheme for all users, use the force_color_scheme_to option in config/initializers/theme.rb:
                  
                    BulletTrain::Themes::Light.force_color_scheme_to = :light  # or :dark
                  
                  You can safely remove the darkMode configuration from tailwind.config.js.
 
                  ------------------------------------------------------------
                  
                WARNING
              end
            end
          end
        end
      end
    end
  end
end
