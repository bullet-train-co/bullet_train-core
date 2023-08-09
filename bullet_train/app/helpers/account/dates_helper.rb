module Account::DatesHelper
  def display_date(timestamp, format: :default, date_format: nil)
    format = date_format if date_format
    localize(local_time(timestamp).to_date, format: format) if timestamp
  end

  def display_time(timestamp, format: :default, time_format: nil)
    format = time_format if time_format
    localize(local_time(timestamp).to_time, format: format) if timestamp
  end

  def display_date_and_time(timestamp, format: :default, date_format: nil, time_format: nil)
    format = "#{date_format} #{time_format}" if date_format && time_format
    localize(local_time(timestamp).to_datetime, format: format) if timestamp
  end

  def local_time(timestamp)
    timestamp&.in_time_zone(current_user.time_zone)
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
