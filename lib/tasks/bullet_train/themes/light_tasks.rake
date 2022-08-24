require "tasks/application"

namespace :bullet_train do
  namespace :themes do
    namespace :light do
      desc "Fork the \"Light\" theme into your local repository."
      task :eject, [:destination] => :environment do |task, args|
        BulletTrain::Themes::Application.eject_theme(get_theme_name_from_task(task), args[:destination])
      end

      desc "Publish your custom theme theme as a Ruby gem."
      task :release, [:theme_name] => :environment do |task, args|
        BulletTrain::Themes::Application.release_theme(get_theme_name_from_task(task), args)
      end

      desc "Install this theme to your main application."
      task :install do |task|
        BulletTrain::Themes::Application.install_theme(get_theme_name_from_task(task))
      end

      desc "List view partials in theme that haven't changed since ejection from \"Light\"."
      task :clean, [:theme] => :environment do |task, args|
        BulletTrain::Themes::Application.clean_theme(get_theme_name_from_task(task), args)
      end

      # Grabs the theme name from task, i.e. - bullet_train:theme:light:eject.
      def get_theme_name_from_task(task)
        task.name.split(":")[2]
      end
    end
  end
end
