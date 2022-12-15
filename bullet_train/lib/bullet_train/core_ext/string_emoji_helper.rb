require "unicode/emoji"

module BulletTrain
  module CoreExt
    module StringEmojiHelper
      def strip_emojis
        gsub(Unicode::Emoji::REGEX, "")
      end

      def only_emoji?
        return false if strip.empty?
        strip_emojis.strip.empty?
      end
    end
  end
end

String.include(BulletTrain::CoreExt::StringEmojiHelper)
