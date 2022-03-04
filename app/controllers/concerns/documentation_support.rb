module DocumentationSupport
  extend ActiveSupport::Concern

  def docs
    @file = params[:page].presence || "index"
    render :docs, layout: "docs"
  end
end
