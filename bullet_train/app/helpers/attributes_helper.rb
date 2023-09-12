module AttributesHelper
  def current_attributes_object
    @_current_attribute_settings&.dig(:object)
  end

  def current_attributes_strategy
    @_current_attribute_settings&.dig(:strategy)
  end

  def with_attribute_settings(object: current_attributes_object, strategy: current_attributes_strategy)
    old_attribute_settings = @_current_attribute_settings
    @_current_attribute_settings = {object: object, strategy: strategy}
    yield
  ensure
    @_current_attribute_settings = old_attribute_settings
  end
end
