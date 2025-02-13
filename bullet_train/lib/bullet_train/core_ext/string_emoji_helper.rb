module BulletTrain
  module CoreExt
    module StringEmojiHelper
      def strip_emojis
        unless Object.const_defined?("Unicode::Emoji")
          raise "Unicode::Emoji is not defined. If you want to use the strip_emoji and/or only_emoji? methods you need to add the `unicode-emoji` gem to your `Gemfile`."
        end
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
