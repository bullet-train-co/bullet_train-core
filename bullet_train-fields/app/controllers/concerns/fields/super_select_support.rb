module Fields::SuperSelectSupport
  extend ActiveSupport::Concern

  def assign_select_options(strong_params, attribute)
    attribute = attribute.to_s
    # We check for nil here because an empty array isn't `present?`, but we want to assign empty arrays.
    if strong_params.key?(attribute) && !strong_params[attribute].nil?
      # filter out the placeholder inputs that arrive along with the form submission.
      strong_params[attribute] = strong_params[attribute].select(&:present?)
    end
  end

  def create_model_if_new(id)
    ActiveSupport::Deprecation.warn(
      "#create_model_if_new is deprecated. " \
      "Use #ensure_valid_id_or_create_model instead. See an example at https://bullettrain.co/docs/field-partials/super-select#accepting-new-entries"
    )
    if id.present?
      unless /^\d+$/.match?(id)
        id = yield(id).id.to_s
      end
    end
    id
  end

  def create_models_if_new(ids)
    ActiveSupport::Deprecation.warn(
      "#create_models_if_new is deprecated. " \
      "Use #ensure_valid_ids_or_create_model instead. See an example at https://bullettrain.co/docs/field-partials/super-select#accepting-new-entries"
    )
    ids.map do |id|
      create_model_if_new(id) do
        yield(id)
      end
    end
  end

  def ensure_valid_id_or_create_model(id_or_string, collection: [], attribute: :id)
    return id_or_string unless id_or_string.present?

    valid_id = collection.find_by(attribute => id_or_string)&.public_send(attribute)
    return valid_id.to_s unless valid_id.nil?

    string = id_or_string
    yield(string, collection)&.id&.to_s
  end

  def ensure_valid_ids_or_create_models(ids_or_strings, collection: [], attribute: :id)
    return ids_or_strings if ids_or_strings.nil? || ids_or_strings.empty?

    valid_ids = collection.valid_attribute_values([ids_or_strings], attribute: attribute).map(&:to_s)
    new_entries = ids_or_strings - valid_ids

    valid_ids + new_entries.map { |string|
      yield(string, collection)&.id&.to_s
    }.compact_blank
  end
end
