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

module ThemeHelper
  # TODO Do we want this to be configurable by downstream applications?
  INVOCATION_PATTERNS = [
    # ❌ This path is included for legacy purposes, but you shouldn't reference partials like this in new code.
    /^account\/shared\//,

    # ✅ This is the correct path to generically reference theme component partials with.
    /^shared\//,
  ]

  def current_theme_object
    @current_theme_object ||= "BulletTrain::Themes::#{current_theme.to_s.classify}::Theme".constantize.new
  end

  def render(options = {}, locals = {}, &block)
    # The theme engine only supports `<%= render 'shared/box' ... %>` style calls to `render`.
    if options.is_a?(String)
      # Initialize a global variable that will cache all resolutions of a given path for the entire life of the server.
      $resolved_theme_partial_paths ||= {}

      # Check whether we've already resolved this partial to render from another path before.
      # If we've already resolved this partial from a different path before, then let's just skip to that.
      # TODO This should be disabled in development so new templates are taken into account without restarting the server.
      if $resolved_theme_partial_paths[options]
        # Override the value in place. This will be respected when we call `super` below.
        options = $resolved_theme_partial_paths[options]
      end
    end

    begin
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
    rescue ActionView::MissingTemplate => exception
      # The theme engine only supports `<%= render 'shared/box' ... %>` style calls to `render`.
      if options.is_a?(String)

        # Does the requested partial path match one of the invocation regexes?
        if (invocation_pattern = INVOCATION_PATTERNS.detect { |regex| options.match?(regex) })
          # Keep track of the original options.
          original_options = options

          # Trim out the base part of the requested partial.
          requested_partial = options.gsub(invocation_pattern, "")

          # TODO We're hard-coding this for now, but this should probably come from the `Current` model.
          current_theme_object.directory_order.each do |theme_path|
            # Update our options from something like `shared/box` to `themes/light/box`.
            options = "themes/#{theme_path}/#{requested_partial}"

            # Try rendering the partial again with the updated options.
            body = super

            # 🏆 If we get this far, then we've found the actual path of the theme partial. We should cache it!
            $resolved_theme_partial_paths[original_options] = options

            # We also need to return whatever the rendered body was.
            return body

          # If calling `render` with the updated options is still resulting in a missing template, we need to
          # keep iterating over `directory_order` to work our way up the theme stack and see if we can find the
          # partial there, e.g. going from `light` to `tailwind` to `base`.
          rescue ActionView::MissingTemplate => _
            next
          end
        end
      end

      # If we weren't able to find the partial in some theme-based place, then just let the original error bubble up.
      raise exception
    end
  end
end
