# TODO This is my best attempt at allowing us to figure out where theme partials might be getting served from.
# We can only inspect the source location of a class (not a module), and this gem has no other classes, so we need this.
# See https://stackoverflow.com/questions/13012109/get-class-location-from-class-object for context.
class BulletTrain::Themes::TailwindCss::PathSnitch
  def self.confess
    # This method allows us to call `BulletTrain::Themes::PathSnitch.method(:confess).source_location` and see where
    # this gem is being served from... which allows us to check it's `view/themes` directory for partials.
  end
end
