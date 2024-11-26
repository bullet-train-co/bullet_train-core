module ObfuscatesId
  module Sluggable
    extend ActiveSupport::Concern

    included do
      before_validation :downcase_slug
      after_validation :set_to_previous_value, on: :update

      if respond_to?(:slug_attribute)
        validates slug_attribute,
          uniqueness: true,
          length: {minimum: 2, maximum: 30},
          format: {with: /\A[a-zA-Z0-9|-]+\Z/}
      end

      validates_with ::RestrictedPathsValidator

      private

      def downcase_slug
        send(attribute_name_setter, send(attribute_name).downcase)
      end

      # Since Rails reloads the same invalid object into the form while displaying errors,
      # we ensure the slug value being referenced to on reloading is the original value which
      # has already been persisted to the database, not the invalid value from the form object.
      def set_to_previous_value
        if errors.any?
          errors.each do |e|
            if e.match?(attribute_name)
              previous_slug_value = send("#{attribute_name}_was")
              send(attribute_name_setter, previous_slug_value)
            end
          end
        end
      end

      def attribute_name
        self.class.send(:slug_attribute)
      end

      def attribute_name_setter
        "#{attribute_name}=".to_sym
      end
    end
  end
end
