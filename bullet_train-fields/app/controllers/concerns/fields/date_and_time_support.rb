module Fields::DateAndTimeSupport
  extend ActiveSupport::Concern

  def assign_date_and_time(strong_params, attribute)
    attribute = attribute.to_s
    time_zone_attribute = "#{attribute}_time_zone"
    if strong_params.dig(attribute).present?
      time_zone = ActiveSupport::TimeZone.new(strong_params[time_zone_attribute] || current_team.time_zone)
      strong_params.delete(time_zone_attribute)
      # TODO: Ensure we're doing this correctly, and try to use Rails' formatting options.
      strong_params[attribute] = time_zone.strptime(strong_params[attribute], "%m/%d/%Y %l:%M %p")
    end
  end
end
