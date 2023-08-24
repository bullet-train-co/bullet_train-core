module Scaffolding
  mattr_accessor :database, default: :postgresql

  def self.mysql?
    database == :mysql
  end

  def self.valid_attribute_type?(type)
    [
      "boolean",
      "buttons",
      "cloudinary_image",
      "color_picker",
      "date_and_time_field",
      "date_field",
      "email_field",
      "emoji_field",
      "file_field",
      "number_field",
      "options",
      "password_field",
      "phone_field",
      "super_select",
      "text_area",
      "text_field",
      "trix_editor"
    ].include?(type.gsub(/{.*}/, "")) # Pop off curly brackets such as `super_select{class_name=Membership}`
  end
end
