module Scaffolding
  def self.valid_attribute_type?(type)
    [
      "boolean",
      "button",
      "cloudinary_image",
      "color_picker",
      "date_and_time_field",
      "date_field",
      "email_field",
      "file_field",
      "options",
      "password_field",
      "phone_field",
      "super_select",
      "text_area",
      "text_field",
      "trix_editor"
    ].include?(type)
  end
end
