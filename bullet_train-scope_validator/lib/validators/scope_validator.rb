class ScopeValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    id_method = "#{attribute}_id".to_sym
    valid_collection = "valid_#{attribute.to_s.pluralize}".to_sym

    if record.send(id_method).present?
      # Don't allow users to assign the IDs of other teams' or users' resources to this attribute.
      unless record.send(valid_collection).exists?(id: record.send(id_method))
        record.errors.add(id_method, :invalid)
      end
    end
  end
end
