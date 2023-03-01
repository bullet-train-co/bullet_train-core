require "test_helper"

class ShowcaseTest < Showcase::PreviewsTest
  helper { def current_theme = :light }
end
