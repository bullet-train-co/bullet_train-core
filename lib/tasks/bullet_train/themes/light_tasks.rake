namespace :bullet_train do
  namespace :themes do
    namespace :light do
      desc "Fork the \"Light\" theme into your local repository."
      task :eject, [:destination] => :environment do |task, args|
        theme_base_path = `bundle show --paths bullet_train-themes-light`.chomp
        puts "Ejecting from Light theme in `#{theme_base_path}`."

        puts "Ejecting Tailwind configuration into `./tailwind.#{args[:destination]}.config.js`."
        `cp #{theme_base_path}/tailwind.light.config.js #{Rails.root}/tailwind.#{args[:destination]}.config.js`

        puts "Ejecting stylesheets into `./app/assets/stylesheets/#{args[:destination]}`."
        `mkdir #{Rails.root}/app/assets/stylesheets`
        `cp -R #{theme_base_path}/app/assets/stylesheets/light #{Rails.root}/app/assets/stylesheets/#{args[:destination]}`
        `cp -R #{theme_base_path}/app/assets/stylesheets/light.tailwind.css #{Rails.root}/app/assets/stylesheets/#{args[:destination]}.tailwind.css`
        `sed -i #{'""' if `echo $OSTYPE`.include?("darwin")} "s/light/#{args[:destination]}/g" #{Rails.root}/app/assets/stylesheets/#{args[:destination]}.tailwind.css`

        puts "Ejecting JavaScript into `./app/javascript/application.#{args[:destination]}.js`."
        `cp #{theme_base_path}/app/javascript/application.light.js #{Rails.root}/app/javascript/application.#{args[:destination]}.js`

        puts "Ejecting all theme partials into `./app/views/themes/#{args[:destination]}`."
        `mkdir #{Rails.root}/app/views/themes`
        `cp -R #{theme_base_path}/app/views/themes/light #{Rails.root}/app/views/themes/#{args[:destination]}`

        puts "Cutting local `Procfile.dev` over from `light` to `#{args[:destination]}`."
        `sed -i #{'""' if `echo $OSTYPE`.include?("darwin")} "s/light/#{args[:destination]}/g" #{Rails.root}/Procfile.dev`

        puts "Cutting local `package.json` over from `light` to `#{args[:destination]}`."
        `sed -i #{'""' if `echo $OSTYPE`.include?("darwin")} "s/light/#{args[:destination]}/g" #{Rails.root}/package.json`

        # Stub out the class that represents this theme and establishes its inheritance structure.
        target_path = "#{Rails.root}/app/lib/bullet_train/themes/#{args[:destination]}.rb"
        puts "Stubbing out a class that represents this theme in `./#{target_path}`."
        `mkdir -p #{Rails.root}/app/lib/bullet_train/themes`
        `cp #{theme_base_path}/lib/bullet_train/themes/light.rb #{target_path}`
        `sed -i #{'""' if `echo $OSTYPE`.include?("darwin")} "s/module Light/module #{args[:destination].titlecase}/g" #{target_path}`
        `sed -i #{'""' if `echo $OSTYPE`.include?("darwin")} "s/TailwindCss/Light/g" #{target_path}`
        `sed -i #{'""' if `echo $OSTYPE`.include?("darwin")} "s/light/#{args[:destination]}/g" #{target_path}`
        ["require", "TODO", "mattr_accessor"].each do |thing_to_remove|
          `grep -v #{thing_to_remove} #{target_path} > #{target_path}.tmp`
          `mv #{target_path}.tmp #{target_path}`
        end
        `standardrb --fix #{target_path}`

        puts "Cutting local project over from `light` to `#{args[:destination]}` in `app/helpers/application_helper.rb`."
        `sed -i #{'""' if `echo $OSTYPE`.include?("darwin")} "s/:light/:#{args[:destination]}/g" #{Rails.root}/app/helpers/application_helper.rb`

        puts "You must restart `bin/dev` at this point, because of the changes to `Procfile.dev` and `package.json`."
      end
    end
  end
end
