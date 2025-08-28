# frozen_string_literal: true

require "test_helper"

class BulletTrain::ScopeValidatorTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::BulletTrain::ScopeValidator::VERSION
  end
end
