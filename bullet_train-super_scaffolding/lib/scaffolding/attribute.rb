# This class provides helpful methods for determining
# when and how we should apply logic for each attribute
# when Super Scaffolding a new model.
#
# For example, we determine which association to use
# based off of the attribute passed to `bin/super-scaffold`
# as opposed to the models (classes) themselves.
# Rails has ActiveRecord::Reflection::AssociationReflection,
# but this is only useful after we've declared the associations.
# Since we haven't declared the associations in the models yet,
# we determine the association for the attribute based on its suffix.

class Scaffolding::Attribute
  attr_accessor :name, :type, :options

  def initialize(raw_string)
    parts = raw_string.split(":")
    self.name = parts.shift
    self.type, self.options = get_type_and_options_from(parts)

    # Ensure `options` is a hash.
    self.options = if self.options
      self.options.split(",").map { |s|
        option_name, option_value = s.split("=")
        [option_name.to_sym, option_value || true]
      }.to_h
    else
      {}
    end

    self.options[:label] ||= "label_string"
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

  def collection_name
    is_ids? ? name_without_ids : name_without_id.pluralize
  end

  def boolean_buttons?
    type == "boolean"
  end

  private

  # i.e. - multiple_buttons:buttons{multiple}
  def get_type_and_options_from(parts)
    parts.join(":").scan(/^(.*){(.*)}/).first || parts.join(":")
  end
end
