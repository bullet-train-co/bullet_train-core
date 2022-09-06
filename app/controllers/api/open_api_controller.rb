module OpenApiHelper
  def indent(string, count)
    lines = string.lines
    first_line = lines.shift
    lines = lines.map { |line| ("  " * count).to_s + line }
    lines.unshift(first_line).join.html_safe
  end

  def components_for(model)
    for_model model do
      indent(render("api/#{@version}/open_api/#{model.name.underscore.pluralize}/components"), 2)
    end
  end

  def current_model
    @model_stack.last
  end

  def for_model(model)
    @model_stack ||= []
    @model_stack << model
    result = yield
    @model_stack.pop
    result
  end

  def paths_for(model)
    for_model model do
      indent(render("api/#{@version}/open_api/#{model.name.underscore.pluralize}/paths"), 1)
    end
  end

  def attribute(attribute)
    heading = t("#{current_model.name.underscore.pluralize}.fields.#{attribute}.heading")
    # TODO A lot of logic to be done here.
    indent("#{attribute}:\n  description: \"#{heading}\"\n  type: string", 2)
  end

  def parameter(attribute)
    heading = t("#{current_model.name.underscore.pluralize}.fields.#{attribute}.heading")
    # TODO A lot of logic to be done here.
    indent("#{attribute}:\n  description: \"#{heading}\"\n  type: string", 2)
  end
end

class Api::OpenApiController < ApplicationController
  helper :open_api

  def set_default_response_format
    request.format = :yaml
  end

  before_action :set_default_response_format

  def index
    @version = params[:version]
    render "api/#{@version}/open_api/index", layout: nil, format: :text
  end
end
