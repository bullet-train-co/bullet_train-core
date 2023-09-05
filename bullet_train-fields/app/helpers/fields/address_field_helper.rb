module Fields::AddressFieldHelper
  def populate_country_options
    ([Addresses::Country.find_by(name: "United States"), Addresses::Country.find_by(name: "Canada")] + Addresses::Country.all).map { |country| [country.name, country.id] }.uniq
  end

  def populate_region_options(address_form)
    return [] if address_form.object.country_id.nil?
    Addresses::Region.where(country_id: address_form.object.country_id).map { |region| [region.name, region.id] }
  end

  def admin_division_label_for(address_form)
    # using country_id because it's fastest, even if this case statement is hard to read
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
    return "" if address.all_blank?

    formatted = [
      address.address_one,
      address.address_two,
      address_city_line_formatted(address),
      address.country&.name&.upcase
    ].reject(&:blank?)

    if one_line
      formatted.join(", ") # simplistic
    else
      simple_format(formatted.join("\n"))
    end
  end

  def address_city_line_formatted(address)
    country_iso2 = address.country&.iso2 # can be nil or empty
    city = address.city
    region = address.region&.name
    postal_code = address.postal_code

    # adapted from https://github.com/cainlevy/snail/blob/master/lib/snail.rb
    # using iso2 property here because it's a port of what's used in snail gem
    # will be cleaned up below if parts missing
    formatted = case country_iso2
    when "CN", "IN"
      "#{city}, #{region}  #{postal_code}"
    when "BR"
      "#{postal_code} #{city}#{"-" unless city.nil? || city.empty? || region.nil? || region.empty?}#{region}"
    when "MX", "SK"
      "#{postal_code} #{city}, #{region}"
    when "IT"
      "#{postal_code} #{city} #{region}"
    when "BY"
      "#{postal_code} #{city}#{"-" unless city.nil? || city.empty? || region.nil? || region.empty?}#{region}"
    when "US", "CA", "AU", nil, ""
      "#{city} #{region}  #{postal_code}"
    when "IL", "DK", "FI", "FR", "DE", "GR", "NO", "ES", "SE", "TR", "CY", "PT", "MK", "BA"
      "#{postal_code} #{city}"
    when "KW", "SY", "OM", "EE", "LU", "BE", "IS", "CH", "AT", "MD", "ME", "RS", "BG", "GE", "PL", "AM", "HR", "RO", "AZ"
      "#{postal_code} #{city}"
    when "NL"
      "#{postal_code}  #{city}"
    when "IE"
      "#{city}, #{region}\n#{postal_code}"
    when "GB", "RU", "UA", "JO", "LB", "IR", "SA", "NZ"
      "#{city}  #{postal_code}" # Locally these may be on separate lines. The USPS prefers the city line above the country line, though.
    when "EC"
      "#{postal_code} #{city}"
    when "HK", "IQ", "YE", "QA", "AL"
      city.to_s
    when "AE"
      "#{postal_code}\n#{city}"
    when "JP"
      "#{city}, #{region}\n#{postal_code}"
    when "EG", "ZA", "IM", "KZ", "HU"
      "#{city}\n#{postal_code}"
    when "LV"
      "#{city}, LV-#{postal_code}".gsub(/LV-\s*$/, "") # undo if no postal code
    when "LT"
      "LT-#{postal_code} #{city}".gsub(/^LT-\s*/, "") # undo if no postal code
    when "SI"
      "SI-#{postal_code} #{city}".gsub(/^SI-\s*/, "") # undo if no postal code
    when "CZ"
      "#{postal_code} #{region}\n#{city}"
    else
      "#{city} #{region}  #{postal_code}"
    end

    # clean up separators when missing pieces
    formatted.strip      # remove extra spaces and newlines before and after
      .gsub(/^,\s*/, "") # remove extra comma from start
      .gsub(/\s*,$/, "") # remove extra comma from end
  end
end
