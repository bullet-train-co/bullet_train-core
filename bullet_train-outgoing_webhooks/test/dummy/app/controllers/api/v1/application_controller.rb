class Api::V1::ApplicationController < ActionController::API
  class << self
    def account_load_and_authorize_resource(model, options, old_options = {})
      true
    end
  end

  def permitted_fields
    []
  end

  def permitted_arrays
    {}
  end

  def process_params(strong_params)
  end
end
