json.extract! event,
  :id,
  BulletTrain::OutgoingWebhooks.parent_association.to_s.foreign_key.to_sym,
  :uuid,
  :event_type_id,
  :subject_id,
  :subject_type,
  :data,
  :created_at
