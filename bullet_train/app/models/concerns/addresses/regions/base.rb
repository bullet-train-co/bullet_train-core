module Addresses::Regions::Base
  extend ActiveSupport::Concern

  included do
    self.data = JSON.parse(File.read(File.expand_path("../../../../../config/addresses/states.json", File.dirname(__FILE__))))

    belongs_to :country, class_name: "Addresses::Country"

    def modified_state_code
      state_code.scan(/\D/).empty? ? name : state_code
    end
  end
end
