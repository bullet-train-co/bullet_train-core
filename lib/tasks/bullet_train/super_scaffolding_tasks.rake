namespace :bullet_train do
  desc "Next-level code generation"
  task :super_scaffolding => :environment do
    BulletTrain::SuperScaffolding::Runner.new.run
  end
end
