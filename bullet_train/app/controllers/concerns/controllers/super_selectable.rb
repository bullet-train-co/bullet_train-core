# SuperSelectable Concern
#
# This concern enables API endpoints to return data in a format suitable for Select2/Super Select dropdowns.
# It works with both API controllers and Account controllers (via delegate_json_to_api).
#
# Usage in API controllers:
#   class Api::V1::ProjectsController < Api::V1::ApplicationController
#     include Api::Controllers::SuperSelectable
#     # ...
#   end
#
# Usage in Account controllers:
#   class Account::ProjectsController < Account::ApplicationController
#     include Controllers::SuperSelectable
#     # ...
#     def index
#       delegate_json_to_api
#     end
#   end
#
# Request format:
#   GET /api/v1/projects?format=super_select
#   GET /api/v1/projects?format=super_select&search=query
#
# Default response format:
#   {
#     "results": [
#       { "id": 1, "text": "Project Name", "ajax": true },
#       { "id": 2, "text": "Another Project", "ajax": true }
#     ],
#     "pagination": true
#   }
#
# Customization:
#   Create a custom template with the +super_select variant:
#   - For API: app/views/api/v1/projects/index.json+super_select.erb
#   - For Account (with delegate_json_to_api): same as API
#
# Search:
#   When params[:search] is provided, it performs a case-insensitive search
#   on the model's label_string column (determined by Model.label_attribute).
#
module Controllers::SuperSelectable
  extend ActiveSupport::Concern

  included do
    before_action :set_super_selectable, only: [:index]
    before_action :apply_super_select_search, only: [:index], if: :super_selectable?
    around_action :render_super_select_response, only: [:index], if: :super_selectable?
  end

  def set_super_selectable
    @super_selectable = params[:format] == "super_select"
    request.variant = :super_select if @super_selectable
  end

  def super_selectable?
    @super_selectable
  end

  # Override delegate_json_to_api to bypass it when super_select format is requested
  # This only applies to account controllers that include Controllers::Base
  def delegate_json_to_api(&block)
    if super_selectable?
      # Don't delegate to API, let our super_select response handler take over
      # The around_action will handle the actual rendering
      return
    end
    
    # Call the original delegate_json_to_api from Controllers::Base
    super(&block)
  end

  def super_select_collection
    # Try to use the collection method if it exists (API controllers)
    if respond_to?(:collection, true) && method(:collection).owner != Controllers::SuperSelectable
      collection
    else
      # Fall back to controller_name based instance variable (Account controllers)
      collection_variable_name = "@#{controller_name}"
      instance_variable_get(collection_variable_name) if instance_variable_defined?(collection_variable_name)
    end
  end

  def super_select_collection=(new_collection)
    # Try to use the collection= method if it exists (API controllers)
    if respond_to?(:collection=, true) && method(:collection=).owner != Controllers::SuperSelectable
      self.collection = new_collection
    else
      # Fall back to controller_name based instance variable (Account controllers)
      collection_variable_name = "@#{controller_name}"
      instance_variable_set(collection_variable_name, new_collection)
    end
  end

  def apply_super_select_search
    return unless params[:search].present?
    
    current_collection = super_select_collection
    return unless current_collection # Skip if no collection is available
    
    # Get the actual column name used by label_string
    # label_attribute returns the first string column by default, or can be overridden
    label_column = current_collection.model.label_attribute
    
    return unless label_column # Skip search if no label attribute is defined
    
    # Check if this is an ActiveHash model
    if current_collection.model < ActiveHash::Base
      # ActiveHash uses regex-based searching
      search_pattern = /#{Regexp.escape(params[:search])}/i
      self.super_select_collection = current_collection.where(label_column => search_pattern)
    else
      # Apply a loose search using ILIKE (PostgreSQL) or LIKE (other databases)
      search_term = "%#{params[:search]}%"
      if current_collection.connection.adapter_name.downcase.include?("postgres")
        self.super_select_collection = current_collection.where("#{label_column}::text ILIKE ?", search_term)
      else
        self.super_select_collection = current_collection.where("#{label_column} LIKE ?", search_term)
      end
    end
  end

  def render_super_select_response
    # For account controllers using delegate_json_to_api, we need to intercept before the delegation happens
    yield # Let the controller action and authorization run first
    
    # Avoid double render - if the controller already rendered, we're done
    return if performed?
    
    current_collection = super_select_collection
    return unless current_collection
    
    # Check if there's a custom variant template
    template_exists = lookup_context.exists?(
      action_name,
      lookup_context.prefixes,
      false,
      [:super_select],
      formats: [:json]
    )
    
    unless template_exists
      # Build default super_select response
      results = current_collection.map do |record|
        {
          id: record.id,
          text: record.try(:label_string) || record.to_s,
          ajax: true
        }
      end
      
      response_data = {
        results: results,
        pagination: @pagy&.next.present?
      }
      
      render json: response_data
    end
    # If template exists, the normal render process will use the variant template
  end
end

