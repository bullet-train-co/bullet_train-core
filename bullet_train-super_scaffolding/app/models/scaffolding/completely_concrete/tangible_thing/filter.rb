class Scaffolding::CompletelyConcrete::TangibleThing::Filter < ApplicationFilter
  self.i18n_scope = "account.#{i18n_scope}"

  def conditions
    [
      condition(:text_field_value, :text),
      condition(:email_field_value, :text),
      condition(:phone_field_value, :text),
      condition(:address_value, :text),
      condition(:text_area_value, :text),
      condition(:action_text_value, :text),

      condition(:sort_order, :numeric),

      condition(:color_picker_value, :option),
      condition(:button_value, :option),
      condition(:boolean_button_value, :option),
      condition(:multiple_button_values, :option),
      condition(:option_value, :option),
      condition(:multiple_option_values, :option),
      condition(:super_select_value, :option),
      condition(:multiple_super_select_values, :option),

      condition(:date_field_value, :date),
      condition(:date_and_time_field_value, :datetime),
      condition(:created_at, :datetime),
      condition(:updated_at, :datetime),
    ]
  end

  def model
    self.class.module_parent
  end
end
