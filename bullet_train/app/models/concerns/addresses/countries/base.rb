module Addresses::Countries::Base
  extend ActiveSupport::Concern

  included do
    self.data = JSON.parse(File.read(File.expand_path("../../../../../config/addresses/countries.json", File.dirname(__FILE__))))

    has_many :regions, class_name: "Addresses::Region"
  end
end
