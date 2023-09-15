class Api::OpenApiController < ApplicationController
  helper "api/open_api"

  def set_default_response_format
    request.format = :yaml
  end

  before_action :set_default_response_format

  def index
    @version = params[:version].match?(/v\d+/) ? params[:version] : raise("Unknown version error")
    render "api/#{@version}/open_api/index", layout: nil, format: :text
  end
end
