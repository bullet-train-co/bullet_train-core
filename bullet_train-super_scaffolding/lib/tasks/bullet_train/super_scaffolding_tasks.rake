namespace :bullet_train do
  desc "Next-level code generation"
  task :super_scaffolding, [:all_options] => :environment do |t, arguments|
    ARGV.pop while ARGV.any?

    arguments[:all_options]&.split&.each do |argument|
      ARGV.push(argument)
    end

    BulletTrain::SuperScaffolding::Runner.new.run
  end
end
