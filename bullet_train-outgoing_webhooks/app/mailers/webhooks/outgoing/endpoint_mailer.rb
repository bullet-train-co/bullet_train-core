class Webhooks::Outgoing::EndpointMailer < ApplicationMailer
  def deactivation_limit_reached(endpoint)
    @endpoint = endpoint
    email = @endpoint.team.formatted_email_address
    return if email.blank?
    set_values(@endpoint)

    mail(
      to: email,
      subject: I18n.t("webhooks.outgoing.endpoint_mailer.deactivation_limit_reached.subject", endpoint_name: @endpoint.name)
    )
  end

  def deactivated(endpoint)
    @endpoint = endpoint
    email = @endpoint.team.formatted_email_address
    return if email.blank?
    set_values(@endpoint)

    mail(
      to: email,
      subject: I18n.t("webhooks.outgoing.endpoint_mailer.deactivated.subject", endpoint_name: @endpoint.name)
    )
  end

  private

  def set_values(endpoint)
    @values ||= {
      endpoint_name: endpoint.name,
      endpoint_events: endpoint.event_type_ids.join(", "),
      app_name: I18n.t("application.name"),
    }
  end
end
