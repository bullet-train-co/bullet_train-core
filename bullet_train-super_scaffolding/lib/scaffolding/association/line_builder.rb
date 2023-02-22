require "scaffolding/class_names_transformer"

class Scaffolding::Association::LineBuilder
  attr_accessor :line, :line_parts, :model, :associated_model, :attribute_type

  # @line [String]: The line we ultimately place in the model file.
  # @line_parts [Array]: The parts we prepare before building the line.
  # @model [String]: The model for which we are building the association line for.
  # @associated_model [String]: The model we are comparing the original model to.
  # @options [Hash]: A list of options for the given association
  # @attribute_type [String]: The attribute type for @model. This helps us
  #                           determine which association @model should have.
  def initialize(model, associated_model, options = {}, attribute_type)
    self.line = ""
    self.line_parts = []
    self.model = model
    self.associated_model = associated_model
    self.options = options
    self.attribute_type = attribute_type
  end

  def build
    # Use line_part ↓
    # line = ...
  end

  def model_is_namespaced?
    is_namespaced?(model)
  end

  def associated_model_is_namespaced?
    is_namespaced?(associated_model)
  end

  private

  def is_namespaced?(model_name)
    model_name.match?("::")
  end

  def add_has_many_association
    line_parts << "has_many :completely_concrete_tangible_things"
    options[:dependent] ||= :destroy

    # We designate `class_name` and `foreign_key` for namespaced models
    # due to how Rails searches for 
    if model_is_namespaced?
      options[:class_name] = "Scaffolding::CompletelyConcrete::TangibleThing"
    end
    if associated_model_is_namespaced?
      options[:foreign_key] = "absolutely_abstract_creative_concept_id"
      options[:inverse_of] = :absolutely_abstract_creative_concept 
    end

    # build line

    # TODO: Return the name of the has_many association
  end

  def add_has_many_through_association
    # Write as a block?
    add_has_many_association
    # Add options[:through] to second part of array?
  end
end
