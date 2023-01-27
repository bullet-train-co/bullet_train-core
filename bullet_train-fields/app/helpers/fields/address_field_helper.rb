module Fields::AddressFieldHelper
  def populate_country_options
    ([Addresses::Country.find_by(name: "United States"), Addresses::Country.find_by(name: "Canada")] + Addresses::Country.all).map { |country| [country.name, country.id] }.uniq
  end

  def populate_region_options(address_form)
    return [] if address_form.object.country_id.nil?
    Addresses::Region.where(country_id: address_form.object.country_id).map { |region| [region.name, region.id] }
  end
  
  def admin_division_label_for(address_form)
    admin_divisions_key = case address_form.object.country_id
      when 233, 31, 142, 239, 101
        :states
      when 39
        :provinces_territories
      when 109
        :prefectures
      when 107, 45, 116, 182, 207, 219, 230, 156, 204
        :provinces
      when 14
        :states_territories
      when 59
        :regions
      when 82, 15
        :federal_states
      when 75
        :departments
      when 105
        :counties
      when 214
        :cantons
      else
        :default
      end
    path = [:addresses, :fields, :admin_divisions, admin_divisions_key]
    t(path.compact.join("."))
  end
  
  def postal_code_label_for(address_form)
    key = if address_form.object.country_id == 233
      :zip_code 
    else
      :postal_code
    end
    path = [:addresses, :fields, key, :label]
    t(path.compact.join("."))
  end
  
  def address_formatted(address, one_line: false)
    formatted = Snail.new(
      :line_1 => address.address_one,
      :line_2 => address.address_two,
      :city => address.city,
      :region => address.region.state_code,
      :postal_code => address.postal_code,
      :country => address.country.iso3
    ).to_s(with_country: true)
    
    if one_line
      formatted.gsub("\n", ", ")
    else
      simple_format formatted
    end
  end
end
