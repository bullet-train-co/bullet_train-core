class RestrictedPathsValidator < ActiveModel::Validator
  def validate(record)
    if record.class.restricted_paths.include?(record.slug)
      record.errors.add record.class.slug_attribute.to_sym, :restricted_path
    end
  end
end
