# This class provides helpful methods for determining when and how we
# should apply logic for each attribute when Super Scaffolding a new model.
#
# For example, we determine which association to use based off of the
# attribute passed to `bin/super-scaffold` as opposed to the models (classes) themselves.
# Rails has ActiveRecord::Reflection::AssociationReflection, but this is only useful
# after we've declared the associations. Since we haven't declared the associations in
# the models yet, we determine the association for the attribute based on its suffix.
#
# i.e. - bin/super-scaffold crud Project tag_ids:super_select{class_name=Projects::Tag}
# Here, we determine the association for the `tag_ids` attribute by its suffix, `_ids`.

class Scaffolding::Attribute
  attr_accessor :name, :type, :options, :scaffolding_type, :attribute_index, :original_type

  # @attribute_definition [String]: The raw attribute name, type, and options that are passed to bin/super-scaffold.
  # @scaffoldng_type [Key]: The type of scaffolder we're using to Super Scaffold the model as a whole.
  # @attribute_index [Integer]: The index taken from the Array of all the attributes of the model.
  def initialize(attribute_definition, scaffolding_type, attribute_index)
    parts = attribute_definition.split(":")
    self.name = parts.shift
    self.type, self.options = get_type_and_options_from(parts)
    self.scaffolding_type = scaffolding_type
    self.attribute_index = attribute_index

    # We mutate `type` within the transformer, so `original_type` allows us
    # to access what the developer originally passed to bin/super-scaffold.
    # (Refer to sql_type_to_field_type_mapping in the transformer)
    self.original_type = type

    # Ensure `options` is a hash.
    self.options = if options
      options.split(",").map { |s|
        option_name, option_value = s.split("=")
        [option_name.to_sym, option_value || true]
      }.to_h
    else
      {}
    end

    options[:label] ||= "label_string"
  end

  def is_first_attribute?
    attribute_index == 0 && scaffolding_type == :crud
  end

  # if this is the first attribute of a newly scaffolded model, that field is required.
  def is_required?
    return false if type == "file_field"
    options[:required] || is_first_attribute?
  end

  def is_association?
    is_belongs_to? || is_has_many?
  end

  def is_belongs_to?
    is_id? && !is_vanilla?
  end

  def is_has_many?
    is_ids? && !is_vanilla?
  end

  def is_vanilla?
    options&.key?(:vanilla)
  end

  def is_multiple?
    options&.key?(:multiple) || is_has_many?
  end

  def is_boolean?
    original_type == "boolean"
  end

  # Sometimes we need all the magic of a `*_id` field, but without the scoping stuff.
  # Possibly only ever used internally by `join-model`.
  def is_unscoped?
    options[:unscoped]
  end

  def is_id?
    name.match?(/_id$/)
  end

  def is_ids?
    name.match?(/_ids$/)
  end

  def name_without_id
    name.gsub(/_id$/, "")
  end

  def name_without_ids
    name.gsub(/_ids$/, "").pluralize
  end

  def name_without_id_suffix
    if is_ids?
      name_without_ids
    elsif is_id?
      name_without_id
    else
      name
    end
  end

  def title_case
    if is_ids?
      # user_ids should be 'Users'
      name_without_ids.humanize.titlecase
    elsif is_id? && is_vanilla?
      "#{name.humanize.titlecase} ID"
    else
      name.humanize.titlecase
    end
  end

  def collection_name
    is_ids? ? name_without_ids : name_without_id.pluralize
  end

  # Field on the show view.
  def partial_name
    return options[:attribute] if options[:attribute]

    case type
    when "trix_editor", "ckeditor"
      "html"
    when "buttons", "super_select", "options", "boolean"
      if is_ids?
        "has_many"
      elsif is_id?
        "belongs_to"
      else
        "option#{"s" if is_multiple?}"
      end
    when "cloudinary_image"
      # TODO: We're preserving cloudinary_image here for backwards compatibility.
      # Remove it in a future major release.
      options[:height] = 200
      "image"
    when "image"
      options[:height] = 200
      "image"
    when "phone_field"
      "phone_number"
    when "date_field"
      "date"
    when "date_and_time_field"
      "date_and_time"
    when "email_field"
      "email"
    when "emoji_field"
      "text"
    when "color_picker"
      "code"
    when "text_field"
      "text"
    when "text_area"
      "text"
    when "file_field"
      "file#{"s" if is_multiple?}"
    when "password_field"
      "text"
    when "number_field"
      "number"
    when "address_field"
      "address"
    else
      raise "Invalid field type: #{type}."
    end
  end

  def default_value
    case type
    when "text_field", "password_field", "text_area"
      "'Alternative String Value'"
    when "email_field"
      "'another.email@test.com'"
    when "phone_field"
      "'+19053871234'"
    when "color_picker"
      "'#47E37F'"
    end
  end

  def special_processing
    case type
    when "date_field"
      "assign_date(strong_params, :#{name})"
    when "date_and_time_field"
      "assign_date_and_time(strong_params, :#{name})"
    when "buttons"
      if is_boolean?
        "assign_boolean(strong_params, :#{name})"
      elsif is_multiple?
        "assign_checkboxes(strong_params, :#{name})"
      end
    when "options"
      if is_multiple?
        "assign_checkboxes(strong_params, :#{name})"
      end
    when "super_select"
      if is_boolean?
        "assign_boolean(strong_params, :#{name})"
      elsif is_multiple?
        "assign_select_options(strong_params, :#{name})"
      end
    end
  end

  private

  # i.e. - multiple_buttons:buttons{multiple}
  def get_type_and_options_from(parts)
    parts.join(":").scan(/^(.*){(.*)}/).first || parts.join(":")
  end
end
