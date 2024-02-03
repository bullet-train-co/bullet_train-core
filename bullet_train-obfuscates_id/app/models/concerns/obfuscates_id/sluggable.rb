module ObfuscatesId
  # We only want to ensure slugging is possible if a developer
  # can generate a `slug` field partial with our scaffolder.
  if defined?(BulletTrain::SuperScaffolding)

    module Sluggable
      extend ActiveSupport::Concern

      included do
        # Alphanumeric downcased URL identifier
        before_validation :downcase_slug

        validates slug_attribute,
          uniqueness: true,
          length: {minimum: 2, maximum: 30},
          format: {with: /\A[a-zA-Z0-9|-]+\Z/}

        validates_with ::RestrictedPathsValidator

        private

        def downcase_slug
          attribute_name = self.class.send(:slug_attribute)
          attribute_name_setter = "#{attribute_name}=".to_sym
          send(attribute_name_setter, send(attribute_name).downcase)
        end
      end
    end

  end
end
