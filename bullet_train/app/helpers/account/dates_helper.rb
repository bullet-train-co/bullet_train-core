module Account::DatesHelper
  def display_date(timestamp, custom_date_format = nil, format: :default, date_format: nil)
    format = date_format if date_format

    if format && format != :default
      localize(local_time(timestamp).to_date, format: format) if timestamp
    else
      # e.g. October 11, 2018
      if custom_date_format
        local_time(timestamp).strftime(custom_date_format)
      elsif local_time(timestamp).year == local_time(Time.now).year
        local_time(timestamp).strftime("%B %-d")
      else
        local_time(timestamp).strftime("%B %-d, %Y")
      end
    end
  end

  def display_time(timestamp, custom_time_format = nil, format: :default, time_format: nil)
    format = time_format if time_format

    if format && format != :default
      localize(local_time(timestamp).to_time, format: format) if timestamp
    else
      # e.g. 4:22 PM
      local_time(timestamp).strftime(custom_time_format || "%l:%M %p")
    end
  end

  def display_date_and_time(timestamp, custom_date_format = nil, custom_time_format = nil, format: :default, date_format: nil, time_format: nil)
    format = "#{date_format} #{time_format}" if date_format && time_format

    if format && format != :default
      localize(local_time(timestamp).to_datetime, format: format) if timestamp
    else
      # e.g. Today at 4:22 PM
      # e.g. Yesterday at 2:12 PM
      # e.g. April 24 at 7:39 AM
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
  end

  def local_time(timestamp)
    timestamp&.in_time_zone(current_user.time_zone)
  end
end
