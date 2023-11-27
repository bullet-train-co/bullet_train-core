# frozen_string_literal: true

Role.class_eval do
  set_root_path "#{Rails.root}/config/models"
  set_filename "roles"
end
