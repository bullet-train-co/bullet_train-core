json.data schema: {object: OpenStruct.new, object_title: I18n.t("webhooks/outgoing/events.fields.data.heading"), object_description: I18n.t("webhooks/outgoing/events.fields.data.heading")} do
  json.id schema: {type: :integer, description: I18n.t("webhooks/outgoing/events.fields.data.id.heading")}
  json.name schema: {type: :string, description: I18n.t("webhooks/outgoing/events.fields.data.name.heading")}
  json.description schema: {type: :string, description: I18n.t("webhooks/outgoing/events.fields.data.description.heading")}
  json.created_at schema: {type: :string, format: "date-time", description: I18n.t("webhooks/outgoing/events.fields.data.created_at.heading")}
  json.updated_at schema: {type: :string, format: "date-time", description: I18n.t("webhooks/outgoing/events.fields.data.updated_at.heading")}
end

json.event_id schema: {type: :string, description: I18n.t("webhooks/outgoing/events.fields.event_id.heading")}
json.event_type schema: {type: :integer, description: I18n.t("webhooks/outgoing/events.fields.event_type.heading")}
json.subject_id schema: {type: :integer, description: I18n.t("webhooks/outgoing/events.fields.subject_id.heading")}
json.subject_type schema: {type: :string, description: I18n.t("webhooks/outgoing/events.fields.subject_type.heading")}
