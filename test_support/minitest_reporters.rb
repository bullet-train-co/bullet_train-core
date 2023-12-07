require "minitest/reporters"

reporters = []

if ENV["BT_TEST_FORMAT"]&.downcase == "dots"
  # The classic "dot style" output:
  # ...S..E...F...
  reporters.push Minitest::Reporters::DefaultReporter.new
else
  # "Spec style" output that shows you which tests are executing as they run:
  # UserTest
  #   test_details_provided_should_be_true_when_details_are_provided  PASS (0.18s)
  reporters.push Minitest::Reporters::SpecReporter.new(print_failure_summary: true)
end

# This reporter generates XML documents into test/reports that are used by CI services to tally results.
# We add it last because doing so make the visible test output a little cleaner.
reporters.push Minitest::Reporters::JUnitReporter.new if ENV["CI"]

Minitest::Reporters.use! reporters
