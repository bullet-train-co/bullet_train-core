json.extract! endpoint,
  :id,
  BulletTrain::OutgoingWebhooks.parent_association.to_s.foreign_key.to_sym,
  :url,
  :name,
  :event_type_ids,
  :deactivation_limit_reached_at,
  :deactivated_at,
  :consecutive_failed_deliveries,
  # 🚅 super scaffolding will insert new fields above this line.
  :created_at,
  :updated_at
