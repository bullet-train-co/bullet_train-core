# frozen_string_literal: true

# We're using this monkey patch: https://github.com/rails/rails/pull/39113#issuecomment-1729082686
# To work around this long-standing bug: https://github.com/rails/rails/issues/38027
# If PR #39113 is ever merged and released in Rails we can ditch this entire file.

require "active_support/core_ext/object/try"
module ActionText
  module Attachments
    module TrixConversion
      def to_trix_attachment(content = trix_attachment_content)
        attributes = full_attributes.dup
        attributes["content"] = content if content
        attributes["url"] = trix_attachable_url if previewable_attachable? && previewable?
        TrixAttachment.from_attributes(attributes)
      end

      def trix_attachable_url
        Rails.application.routes.url_helpers.rails_blob_url(preview_image.blob, only_path: true)
      end
    end
  end
end
