module RefreshFieldsHelper
  def accept_query_string_override_for(form, method)
    field_name = form.field_name(method)
    nested_keys = Rack::Utils.parse_nested_query(field_name)
    
    dig_path = []
    while !nested_keys.nil? && nested_keys.keys.size
      dig_path << nested_keys.keys.first.to_sym
      nested_keys = nested_keys[dig_path.last.to_s]
    end
    
    new_value = params.dig(*dig_path)
    return if new_value.nil?
    
    form.object[method] = new_value
  end
end