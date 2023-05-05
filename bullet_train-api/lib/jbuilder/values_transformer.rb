# frozen_string_literal: true

require "jbuilder"

module ValuesTransformer
  def _set_value(key, value)
    value = value.body if value.is_a?(ActionText::RichText)

    super(key, value)
  end
end

::Jbuilder.prepend ValuesTransformer
