json.extract! endpoint,
  :id,
  BulletTrain::OutgoingWebhooks.parent_association.to_s.foreign_key.to_sym,
  :url,
  :name,
  :event_type_ids,
  # 🚅 super scaffolding will insert new fields above this line.
  :created_at,
  :updated_at

# Avoid spilling secrets via the API. We still need to show it once on create so
# endpoints created programmaticly via the API can save it and use it to verify
# the signature.
json.webhook_secret endpoint.webhook_secret if endpoint.previously_new_record?
