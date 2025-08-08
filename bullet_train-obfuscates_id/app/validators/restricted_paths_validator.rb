class RestrictedPathsValidator < ActiveModel::Validator
  def validate(record)
    if record.class.restricted_paths.include?(record.slug)
      record.errors.add record.class.slug_attribute, :restricted_path
    end
  end
end
