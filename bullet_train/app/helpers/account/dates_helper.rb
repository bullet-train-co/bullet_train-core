module Account::DatesHelper
  def display_date(timestamp, custom_date_format = nil, format: :default, date_format: nil)
    date_format ||= custom_date_format
    format = date_format if date_format
    localize(local_time(timestamp).to_date, format: format) if timestamp
  end

  def display_time(timestamp, custom_time_format = nil, format: :default, time_format: nil)
    time_format ||= custom_time_format
    format = time_format if time_format
    localize(local_time(timestamp).to_time, format: format) if timestamp
  end

  def display_date_and_time(timestamp, custom_date_format = nil, custom_time_format = nil, format: :default, date_format: nil, time_format: nil)
    date_format ||= custom_date_format
    time_format ||= custom_time_format
    format = "#{date_format} #{time_format}" if date_format && time_format
    localize(local_time(timestamp).to_datetime, format: format) if timestamp
  end

  def local_time(timestamp)
    timestamp&.in_time_zone(current_user.time_zone)
  end
end
