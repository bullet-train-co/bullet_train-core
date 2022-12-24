json.data do
  json.id schema: {type: :integer}
  json.name schema: {type: :string, required: true}
  json.description schema: {type: :string}
  json.created_at schema: {type: :string, format: "date-time"}
  json.created_at schema: {type: :string, format: "date-time"}
end

json.event_id schema: {type: :string}
json.event_type schema: {type: :integer}
json.subject_id schema: {type: :integer}
json.subject_type schema: {type: :string}
