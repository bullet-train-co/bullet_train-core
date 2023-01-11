module DocumentationSupport
  extend ActiveSupport::Concern

  def docs
    target = params[:page].presence || "index"

    # TODO For some reason this didn't work on Heroku.
    # all_paths = ([Rails.root.to_s] + `bundle show --paths`.lines.map(&:chomp))
    # @path = all_paths.map { |path| path + "/docs/#{target}.md" }.detect { |path| File.exist?(path) }

    # TODO Trying to just brute force this for now.
    @path = `bundle show bullet_train`.chomp + "/docs/#{target}.md"

    render :docs, layout: "docs"
  end
end
