module DocumentationSupport
  extend ActiveSupport::Concern

  def docs
    target = params[:page].presence || "index"
    files = `find -L tmp/gems/*/docs | grep \.md`.lines.map(&:chomp).sort
    @file = files.detect { |file| file.include?(target) }
    render :docs, layout: "docs"
  end
end
