json.extract! endpoint,
  :id,
  BulletTrain::OutgoingWebhooks.parent_association.to_s.foreign_key.to_sym,
  :url,
  :name,
  :event_type_ids,
  # 🚅 super scaffolding will insert new fields above this line.
  :created_at,
  :updated_at
