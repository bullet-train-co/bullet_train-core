# Our custom devise views are housed in `bullet_train-base`, but they're overwritten
# by devise's standard views if the devise gem is declared after `bullet_train`.
# To ensure we use our custom views, we temporarily unregister the original devise
# views path from the FileSystemResolver, add our custom path, and find the views that way.
module ActionView
  class LookupContext
    module ViewPaths
      def find(name, prefixes = [], partial = false, keys = [], options = {})
        name, prefixes = normalize_name(name, prefixes)
        details, details_key = detail_args_for(options)

        devise_view = false
        prefixes.each do |prefix|
          if prefix.match?(/devise/)
            devise_view = true
            break
          end
        end

        resolver = if name == "devise" || devise_view
          original_devise_view_path = BulletTrain::Themes::Light.original_devise_path
          bullet_train_resolver = @view_paths.paths.reject do |resolver|
            resolver.path.match?(original_devise_view_path)
          end
          PathSet.new(bullet_train_resolver)
        else
          @view_paths
        end

        resolver.find(name, prefixes, partial, details, details_key, keys)
      end
      alias_method :find_template, :find
    end
  end
end

# When rendering collections (i.e. - @foos) with partials, Rails uses this method to build a string
# such as `foos/foo`. This ultimately references the partial `app/views/foos/_foo.html.erb` for rendering.
# However, Super Scaffolding class names are namespaced in such a way that `collection` below
# returns a string with the full path: `scaffolding/absolutely_abstract/creative_concepts/creative_concept`.
# We only need `creative_concepts/creative_concept`, so we split the string and remove any unncessary elements.
module ActiveModel
  module Conversion
    module ClassMethods
      def _to_partial_path # :nodoc:
        @_to_partial_path ||= begin
          element = ActiveSupport::Inflector.underscore(ActiveSupport::Inflector.demodulize(name))
          collection = ActiveSupport::Inflector.tableize(name)
          "#{collection.split("/").last}/#{element}"
        end
      end
    end
  end
end

module ThemeHelper
  def current_theme_object
    @current_theme_object ||= "BulletTrain::Themes::#{current_theme.to_s.classify}::Theme".constantize.new
  end

  def render(options = {}, locals = {}, &block)
    options = current_theme_object.resolved_partial_path_for(@lookup_context, options, locals) || options

    # This is where we try to just lean on Rails default behavior. If someone renders `shared/box` and also has a
    # `app/views/shared/_box.html.erb`, then no error will be thrown and we will have never interfered in the normal
    # Rails behavior.
    #
    # We also don't do anything special if someone renders `shared/box` and we've already previously resolved that
    # partial to be served from `themes/light/box`. In that case, we've already replaced `shared/box` with the
    # actual path of the partial, and Rails will do the right thing from this point.
    #
    # However, if one of those two situations isn't true, then this call here will throw an exception and we can
    # perform the appropriate magic to figure out where amongst the themes the partial should be rendering from.
    super
  end
end
