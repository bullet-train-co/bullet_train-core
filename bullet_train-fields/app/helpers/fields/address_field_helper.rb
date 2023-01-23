module Fields::AddressFieldHelper
  def populate_country_options
    ([Addresses::Country.find_by(name: "United States"), Addresses::Country.find_by(name: "Canada")] + Addresses::Country.all).map { |country| [country.name, country.id] }.uniq
  end

  def populate_region_options(address_form)
    Addresses::Region.where(country_id: address_form.object.country_id).map { |region| [region.name, region.id] }
  end
end
