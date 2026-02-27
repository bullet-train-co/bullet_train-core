# This is to render previews for video attachments in Action Text
# Source: https://mileswoodroffe.com/articles/action-text-video-support
#
# NOTE: This is all way more verbose that I'd like it to be. Maybe we can
# slim it down if this Rails issue is ever fixed:
# https://github.com/rails/rails/issues/54478

# We require this here since we need ActionText things below.
# This won't do anything for most apps, but if you happen to be trying to use
# BT in a non-starter-repo app that was generated with the `--minimal` flag,
# then this will save you some head scratching.
# https://github.com/bullet-train-co/bullet_train-core/issues/1288
require "action_text/engine"

Rails.application.config.after_initialize do
  default_allowed_attributes = Rails::HTML5::Sanitizer.safe_list_sanitizer.allowed_attributes + ActionText::Attachment::ATTRIBUTES.to_set
  custom_allowed_attributes = Set.new(%w[controls poster type])
  ActionText::ContentHelper.allowed_attributes = (default_allowed_attributes + custom_allowed_attributes).freeze

  default_allowed_tags = Rails::HTML5::Sanitizer.safe_list_sanitizer.allowed_tags + Set.new([ActionText::Attachment.tag_name, "figure", "figcaption"])
  custom_allowed_tags = Set.new(%w[audio video source])
  ActionText::ContentHelper.allowed_tags = (default_allowed_tags + custom_allowed_tags).freeze
end
