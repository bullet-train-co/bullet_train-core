module DocumentationSupport
  extend ActiveSupport::Concern

  BULLET_TRAIN_BASE_PATH = `bundle show bullet_train`.chomp

  def docs
    target = params[:page].presence || "index"

    # TODO For some reason this didn't work on Heroku.
    # all_paths = ([Rails.root.to_s] + `bundle show --paths`.lines.map(&:chomp))
    # @path = all_paths.map { |path| path + "/docs/#{target}.md" }.detect { |path| File.exist?(path) }

    @path = "#{BULLET_TRAIN_BASE_PATH}/docs/#{target}.md"

    render :docs, layout: "docs"
  end
end
