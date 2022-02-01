require "bullet_train/super_scaffolding/version"
require "bullet_train/super_scaffolding/engine"

module BulletTrain
  module SuperScaffolding
    mattr_accessor :template_paths, default: []

    class Runner
      def run
        # Make `rake` invocation compatible with how this was run historically.
        ARGV.shift

        require "scaffolding/script"
      end
    end
  end
end
