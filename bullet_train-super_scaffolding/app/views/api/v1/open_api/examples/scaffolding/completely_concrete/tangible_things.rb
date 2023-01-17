BulletTrain::Api.define do
  example :scaffolding_completely_concrete_tangible_thing, class: "Scaffolding::CompletelyConcrete::TangibleThing" do
    absolutely_abstract_creative_concept { BulletTrain::Api.example(:scaffolding_absolutely_abstract_creative_concept, completely_concrete_tangible_things: [self.instance]) }
    text_field_value { "Example String" }
    button_value { "one" }
    cloudinary_image_value { "https://res.cloudinary.com/ab1cd2ef3/image/upload/v1234567/example-image.jpg" }
    date_field_value { "2023-12-03" }
    date_and_time_field_value { "2023-11-05" }
    email_field_value { "email@example.com" }
    password_field_value { "example-password" }
    phone_field_value { "+1234567890" }
    super_select_value { "three" }
    text_area_value { "Example Text" }
    action_text_value { "Example Action Text" }
    sort_order { 1 }
    multiple_button_values { ["one", "two"] }
    multiple_super_select_values  { ["one", "two"] }
    color_picker_value { "#006EF4" }
    boolean_button_value { "true" }
    option_value { "one" }
    multiple_option_values  { ["one", "two"] }
  end
end
