module BulletTrain
  module SuperScaffolding
    class Scaffolder
      attr_accessor :argv

      def initialize(argv, options)
        # Just setting these like this so the code we moved around still runs.
        self.argv = argv
        @options = options
      end
    end
  end
end
