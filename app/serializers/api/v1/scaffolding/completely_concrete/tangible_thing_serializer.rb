class Api::V1::Scaffolding::CompletelyConcrete::TangibleThingSerializer < Api::V1::ApplicationSerializer
  set_type "scaffolding/completely_concrete/tangible_thing"
  singleton_class.include Rails.application.routes.url_helpers

  attributes :id,
    :absolutely_abstract_creative_concept_id,
    # 🚅 skip this section when scaffolding.
    :text_field_value,
    :button_value,
    :multiple_button_values,
    :color_picker_value,
    :cloudinary_image_value,
    :date_field_value,
    :date_and_time_field_value,
    :email_field_value,
    :password_field_value,
    :phone_field_value,
    :option_value,
    # :multiple_option_values,
    :super_select_value,
    # :multiple_super_select_values,
    # :text_area_value,
    # :action_text_value,
    # 🚅 stop any skipping we're doing now.
    # 🚅 super scaffolding will insert new fields above this line.
    :created_at,
    :updated_at

  # We can serialize file fields with jsonapi-serializer in the following way.
  # https://github.com/jsonapi-serializer/jsonapi-serializer/issues/131
  attribute :file_field_value do |object|
    rails_blob_path(object.file_field_value, disposition: "attachment", only_path: true) if object.file_field_value.attached?
  end

  belongs_to :absolutely_abstract_creative_concept, serializer: Api::V1::Scaffolding::AbsolutelyAbstract::CreativeConceptSerializer
end
