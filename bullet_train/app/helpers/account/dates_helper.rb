module Account::DatesHelper
  # e.g. October 11, 2018
  def display_date(timestamp, custom_date_format = nil)
    return nil unless timestamp
    if custom_date_format
      local_time(timestamp).strftime(custom_date_format)
    elsif local_time(timestamp).year == local_time(Time.now).year
      local_time(timestamp).strftime("%B %-d")
    else
      local_time(timestamp).strftime("%B %-d, %Y")
    end
  end

  # e.g. October 11, 2018 at 4:22 PM
  # e.g. Yesterday at 2:12 PM
  # e.g. April 24 at 7:39 AM
  def display_date_and_time(timestamp, custom_date_format = nil, custom_time_format = nil)
    return nil unless timestamp

    # today?
    if local_time(timestamp).to_date == local_time(Time.now).to_date
      "Today at #{display_time(timestamp, custom_time_format)}"
    # yesterday?
    elsif (local_time(timestamp).to_date) == (local_time(Time.now).to_date - 1.day)
      "Yesterday at #{display_time(timestamp, custom_time_format)}"
    else
      "#{display_date(timestamp, custom_date_format)} at #{display_time(timestamp, custom_time_format)}"
    end
  end

  # e.g. 4:22 PM
  def display_time(timestamp, custom_time_format = nil)
    local_time(timestamp).strftime(custom_time_format || "%l:%M %p")
  end

  def local_time(time)
    return time if current_user.time_zone.nil?
    time.in_time_zone(current_user.time_zone)
  end

  def am_pm?
    !"#{I18n.t("time.am", fallback: false, default: "")}#{I18n.t("time.pm", fallback: false, default: "")}".empty?
  end

  def time_zone_name_to_id
    ActiveSupport::TimeZone.all.map { |tz| {tz.name.to_s => tz.tzinfo.name} }.reduce({}, :merge)
  end

  def current_time_zone
    current_time_zone_name = current_user&.time_zone || current_user&.current_team&.time_zone || "UTC"
    ActiveSupport::TimeZone.find_tzinfo(current_time_zone_name).name
  end
end
