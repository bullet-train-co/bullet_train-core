namespace :bullet_train do
  desc "Symlink registered gems in `./tmp/gems` so their views, etc. can be inspected by Tailwind CSS."
  task :link_gems => :environment do
    if Dir.exists?("tmp/gems")
      puts "Removing previously linked gems."
      `rm -f tmp/gems/*`
    else
      if File.exists?("tmp/gems")
        raise "A file named `tmp/gems` already exists? It has to be removed before we can create the required directory."
      end

      puts "Creating 'tmp/gems' directory."
      `mkdir tmp/gems`
    end

    `touch tmp/gems/.keep`

    BulletTrain.linked_gems.each do |linked_gem|
      target = `bundle show #{linked_gem}`.chomp
      if target.present?
        puts "Linking '#{linked_gem}' to '#{target}'."
        puts `ln -s #{target} tmp/gems/#{linked_gem}`
      end
    end
  end

  desc "Figure out where something is coming from."
  task :resolve, [:all_options] => :environment do |t, arguments|
    ARGV.pop while ARGV.any?

    arguments[:all_options]&.split&.each do |argument|
      ARGV.push(argument)
    end

    if ARGV.first.present?
      BulletTrain::Resolver.new(ARGV.first).run(eject: ARGV.include?("--eject"), open: ARGV.include?("--open"), force: ARGV.include?("--force"))
    else
      $stderr.puts "\n🚅 Usage: `bin/resolve [path, partial, or URL] (--eject) (--open)`\n".blue
    end
  end
end
