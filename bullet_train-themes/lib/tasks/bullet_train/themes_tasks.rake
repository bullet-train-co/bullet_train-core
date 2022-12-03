require_relative "../application"

namespace :bullet_train do
  namespace :themes do
    task :install, [:theme_name] => :environment do |task, args|
      BulletTrain::Themes::Application.install_theme(args[:theme_name])
    end
  end
end
