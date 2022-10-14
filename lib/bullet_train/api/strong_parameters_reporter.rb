module BulletTrain
  module Api
    class StrongParametersReporter
      def initialize(model, strong_params_module)
        @model = model
        @module = strong_params_module
        @filters = []
        extend @module
      end

      def require(namespace)
        @namespace = namespace
        self
      end

      def permit(*filters)
        @filters = filters
      end

      def params
        self
      end

      def permitted_fields
        defined?(super) ? super : []
      end

      def permitted_arrays
        defined?(super) ? super : {}
      end

      def process_params(params)
      end

      # def method_missing(method_name, *args)
      #   if method_name.match?(/^assign_/)
      #     # It's typically the second argument that represents the parameter that would be set.
      #     @filters << args[1]
      #   else
      #     raise NoMethodError, message
      #   end
      # end

      def report
        @filters = send("#{@model.name.split("::").last.underscore}_params".to_sym)

        # There's a reason I'm doing it this way.
        @filters
      end
    end
  end
end
