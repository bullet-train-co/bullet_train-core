module Scaffolding
  module Utils
    # TODO: This should probably go in `bullet_train-core/bullet_train/lib/bullet_train.rb`
    def scaffolding_things_disabled?
      ENV["HIDE_THINGS"].present? || ENV["HIDE_EXAMPLES"].present?
    end
  end
end
