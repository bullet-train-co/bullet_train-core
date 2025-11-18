module Api::Controllers::SuperSelectable
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

  def apply_super_select_search
    return unless params[:search].present?
    
    # Get the actual column name used by label_string
    # label_attribute returns the first string column by default, or can be overridden
    label_column = collection.model.label_attribute
    
    return unless label_column # Skip search if no label attribute is defined
    
    # Apply a loose search using ILIKE (PostgreSQL) or LIKE (other databases)
    search_term = "%#{params[:search]}%"
    if collection.connection.adapter_name.downcase.include?("postgres")
      self.collection = collection.where("#{label_column}::text ILIKE ?", search_term)
    else
      self.collection = collection.where("#{label_column} LIKE ?", search_term)
    end
  end

  def render_super_select_response
    yield # Let the controller action and authorization run first
    
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
      results = collection.map do |record|
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