module AttributesHelper
  def current_attributes_object
    @_attributes_helper_objects&.last
  end

  def current_attributes_strategy
    @_attributes_helper_strategies&.last
  end

  def with_attribute_settings(options)
    @_attributes_helper_objects ||= []
    @_attributes_helper_strategies ||= []

    if options[:object]
      @_attributes_helper_objects << options[:object]
    end

    if options[:strategy]
      @_attributes_helper_strategies << options[:strategy]
    end

    yield

    if options[:strategy]
      @_attributes_helper_strategies.pop
    end

    if options[:object]
      @_attributes_helper_objects.pop
    end
  end
end
