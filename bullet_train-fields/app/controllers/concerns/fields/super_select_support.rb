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
      "Use #ensure_backing_models_on instead. See examples at https://bullettrain.co/docs/field-partials/super-select#accepting-new-entries"
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
      "Use #ensure_backing_models_on instead. See examples at https://bullettrain.co/docs/field-partials/super-select#accepting-new-entries"
    )
    ids.map do |id|
      create_model_if_new(id) do
        yield(id)
      end
    end
  end

  # See examples at https://bullettrain.co/docs/field-partials/super-select#accepting-new-entries
  def ensure_backing_models_on(collection, id: nil, ids: [id])
    ids = ids.compact_blank
    return ids if ids.empty?

    existing_ids = collection.where(id: ids).ids.map(&:to_s)
    new_ids = ids.without(existing_ids).filter_map { yield(collection, _1)&.id&.to_s }
    (existing_ids + new_ids).then { id ? _1.first : _1 }
  end
end
