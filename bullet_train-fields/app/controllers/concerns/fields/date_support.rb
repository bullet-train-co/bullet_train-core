module Fields::DateSupport
  extend ActiveSupport::Concern

  def assign_date(strong_params, attribute)
    deprecator = ActiveSupport::Deprecation.new("2.0", "BulletTrain::Fields")
    deprecator.deprecation_warning(
      "assign_date",
      "Please assign an ISO8601 date string as field value instead and remove all assign_date assignments,
      see https://ruby-doc.org/3.2.2/exts/date/Date.html"
    )
    attribute = attribute.to_s
    if strong_params.dig(attribute).present?
      begin
        strong_params[attribute] = Date.iso8601(strong_params[attribute])
      rescue ArgumentError
        parsed_value = Chronic.parse(strong_params[attribute])
        return nil unless parsed_value
        strong_params[attribute] = parsed_value.to_date
      end
    end
  end
end
