module Account::DatesHelper
  def display_date(timestamp, format: :defaul)
    localize(local_time(timestamp).to_date, format: format) if timestamp
  end

  def display_time(timestamp, format: :default)
    localize(local_time(timestamp).to_time, format: format) if timestamp
  end

  def display_date_and_time(timestamp, format: :default)
    localize(local_time(timestamp).to_datetime, format: format) if timestamp
  end

  def local_time(timestamp)
    timestamp&.in_time_zone(current_user.time_zone || Time.zone)
  end
end
