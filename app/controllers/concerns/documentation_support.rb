module DocumentationSupport
  extend ActiveSupport::Concern

  def docs
    target = params[:page].presence || "index"
    all_paths = ([Rails.root.to_s] + `bundle show --paths`.lines.map(&:chomp))
    @path = all_paths.map { |path| path + "/docs/#{target}.md" }.detect { |path| File.exist?(path) }
    render :docs, layout: "docs"
  end
end
