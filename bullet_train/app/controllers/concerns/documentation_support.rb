module DocumentationSupport
  extend ActiveSupport::Concern

  BULLET_TRAIN_BASE_PATH = Gem::Specification.find_by_name("bullet_train").gem_dir

  def docs
    target = params[:page].presence || "index"

    @path = "#{BULLET_TRAIN_BASE_PATH}/docs/#{target}.md"

    render :docs, layout: "docs"
  end
end
