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
    if id.present?
      unless /^\d+$/.match?(id)
        id = yield(id).id.to_s
      end
    end
    id
  end

  def create_models_if_new(ids)
    ids.map do |id|
      create_model_if_new(id) do
        yield(id)
      end
    end
  end

  def id_or_create_from_string(id_or_string)
    return id_or_string unless id_or_string.present?

    if /^\d+$/.match?(id_or_string)
      id_or_string
    else
      yield(id_or_string).id.to_s
    end
  end

  def ensure_valid_id_or_create_model(id_or_string, collection: [], attribute: :id)
    return id_or_string unless id_or_string.present?

    id = id_or_create_from_string(id_or_string) do |string|
      yield(string)
    end

    collection.valid_attribute_values([id], attribute: attribute).first
  end

  def ensure_valid_ids_or_create_model(ids_or_strings, collection: [], attribute: :id)
    ids = ids_or_strings.map do |id_or_string|
      id_or_create_from_string(id_or_string) do |string|
        yield(string)
      end
    end
    collection.valid_attribute_values([ids], attribute: attribute).first
  end

end
