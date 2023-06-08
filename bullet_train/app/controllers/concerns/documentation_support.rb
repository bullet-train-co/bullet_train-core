module DocumentationSupport
  extend ActiveSupport::Concern

  def docs
    target = params[:page].presence || "index"

    # TODO For some reason this didn't work on Heroku.
    # all_paths = ([Rails.root.to_s] + `bundle show --paths`.lines.map(&:chomp))
    # @path = all_paths.map { |path| path + "/docs/#{target}.md" }.detect { |path| File.exist?(path) }

    @path = Rails.cache.fetch('bullet_train_path') { `bundle show bullet_train`.chomp }
    @path += "/docs/#{target}.md"

    render :docs, layout: "docs"
  end
end
