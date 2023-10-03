module DependentFieldsFrameHelper
  def accept_query_string_override_for(form, method)
    field_name = form.field_name(method)

    new_value = new_value_from_query_string(field_name)
    return if new_value.nil?

    form.object[method] = new_value
  end

  private

  def new_value_from_query_string(field_name)
    params.dig(*params_dig_path_for_field_name(field_name))
  end

  def params_dig_path_for_field_name(field_name)
    dig_path = []

    nested_keys = Rack::Utils.parse_nested_query(field_name)

    while !nested_keys.nil? && nested_keys.keys.size
      key = nested_keys.keys.first
      dig_path << key.to_sym
      nested_keys = nested_keys[key]
    end

    dig_path
  end
end
