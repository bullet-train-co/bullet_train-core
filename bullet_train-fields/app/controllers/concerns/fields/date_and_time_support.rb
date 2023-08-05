module Fields::DateAndTimeSupport
  extend ActiveSupport::Concern

  def assign_date_and_time(strong_params, attribute)
    deprecator = ActiveSupport::Deprecation.new("2.0", "BulletTrain::Fields")
    deprecator.deprecation_warning(
      "assign_date_and_time",
      "Please assign an ISO8601 datetime string as form field value instead and remove all assign_date_and_time assignments,
      see https://ruby-doc.org/3.2.2/exts/date/DateTime.html"
    )
    attribute = attribute.to_s
    time_zone_attribute = "#{attribute}_time_zone"
    if strong_params.dig(attribute).present?
      begin
        strong_params[attribute] = DateTime.iso8601(strong_params[attribute])
      rescue ArgumentError
        time_zone = ActiveSupport::TimeZone.new(strong_params[time_zone_attribute] || current_team.time_zone)
        strong_params.delete(time_zone_attribute)
        strong_params[attribute] = time_zone.strptime(strong_params[attribute], t("global.formats.date_and_time"))
      end
    end
  end
end
