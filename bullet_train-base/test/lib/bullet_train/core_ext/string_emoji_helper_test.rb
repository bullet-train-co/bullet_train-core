require "test_helper"

class StringEmojiHelperTest < ActiveSupport::TestCase
  test "#strip_emojis should remove all emojis from the string" do
    assert_equal "Hello !", "Hello 🌎!".strip_emojis
  end

  test "#only_emoji? returns true if the string only contains emojis" do
    assert "🌎".only_emoji?
  end

  test "#only_emoji? returns false if the string does not only contains emojis" do
    refute "Hello 🌎!".only_emoji?
  end
end
