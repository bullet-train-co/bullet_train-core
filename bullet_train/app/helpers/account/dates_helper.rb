module Account::DatesHelper
  def display_date(timestamp, format: nil)
    return nil unless timestamp
    timestamp = set_to_user_time_zone(timestamp)
    formatted_timestamp(timestamp, format: format)
  end
  alias_method :display_date_and_time, :display_date

  private

  # If the format is a Symbol, we use the standard Rails formatting.
  # https://guides.rubyonrails.org/i18n.html#adding-date-time-formats
  def formatted_timestamp(timestamp, format: nil)
    format ||= :default
    format.is_a?(Symbol) ? l(timestamp, format: format) : timestamp.strftime(format)
  end

  def set_to_user_time_zone(timestamp)
    return timestamp if current_user.time_zone.nil?
    is_date = timestamp.is_a?(Date)
    timestamp = timestamp.in_time_zone(current_user.time_zone)
    is_date ? timestamp.to_date : timestamp
  end
end
