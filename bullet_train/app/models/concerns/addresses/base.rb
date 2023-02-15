module Addresses::Base
  extend ActiveSupport::Concern

  included do
    belongs_to :addressable, polymorphic: true
    belongs_to :country, class_name: "Addresses::Country"
    belongs_to :region, class_name: "Addresses::Region"

    def valid_address?
      address_one? && city? && region_id? && country_id? && postal_code?
    end

    def all_blank?(attributes = {})
      return super(attributes) unless attributes.empty?
      !(address_one? || address_two? || city? || region_id? || country_id? || postal_code?)
    end
  end
end
