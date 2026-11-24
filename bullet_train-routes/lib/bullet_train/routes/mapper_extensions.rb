module BulletTrain
  module Routes
    # Adds a `model` method to the Rails routing DSL. It's a drop-in substitute for
    # `resources` that takes a model name instead of a resource name, and draws the
    # shallow, namespaced routes described in the README.
    #
    # Every model is drawn in exactly one place:
    #
    #   * A model with no `model` parent is drawn at its canonical location — its module
    #     path as namespaces, e.g. `model "Projects::Deliverable"` draws the same routes
    #     as `namespace :projects { resources :deliverables }`.
    #
    #   * A model nested inside another `model` is drawn under its parent's canonical path
    #     with `shallow: true`, so its collection actions (index/new/create) nest under the
    #     parent while its member actions stay at the child's own canonical path.
    #
    # Rails' own `shallow:`, `shallow_path:` and `shallow_prefix:` do the splitting, so the
    # block you pass is evaluated exactly once and every `resources` option still applies.
    module MapperExtensions
      # Draws routes for `name`, which can be a model name ("Projects::Deliverable"), a
      # symbol (:project) or a model class. Accepts the same options and block as
      # `resources`.
      def model(name, options = nil, *extra, &block)
        if extra.any?
          raise ArgumentError, "`model` takes a model name and an options hash, but #{extra.count + 2} arguments were given. Did you mean `model #{name.inspect}, #{(options || {}).merge(extra.first.is_a?(Hash) ? extra.first : {}).inspect}`?"
        end

        unless options.nil? || options.is_a?(Hash)
          raise ArgumentError, "`model` takes an options hash as its second argument, but got #{options.inspect}. Unlike `resources`, `model` only draws one model at a time."
        end

        # A model declared directly in another model's block is that model's child, and its
        # member routes have to be drawn outside the parent's block to stay shallow. Record
        # the declaration and let the parent draw it once its block closes.
        #
        # A model declared inside some further block (`namespace`, `scope`, `resources`…) is
        # not deferred: we draw it where it was written, so that block still applies, exactly
        # as it would to `resources`. Nesting it under the enclosing model shallowly would
        # mean discarding the scope the developer opened.
        if (pending = bullet_train_pending_models) && bullet_train_in_parent_scope?
          pending << [name, options, block]
          return
        end

        bullet_train_draw_model(bullet_train_model_segments(name), options || {}, nil, &block)
      end

      private

      # Holds child `model` declarations captured while a parent's block is being evaluated.
      # `nil` means we aren't inside a `model` block, so declarations are drawn immediately.
      def bullet_train_pending_models
        @bullet_train_pending_models ||= nil
      end

      # True when we're still in the scope the parent's block opened in, rather than inside
      # a further block the developer opened within it. Rails replaces `@scope` for each
      # nested block, so comparing identity is enough.
      def bullet_train_in_parent_scope?
        @scope.equal?(@bullet_train_block_scope ||= nil)
      end

      # "Projects::Deliverable" => ["projects", "deliverable"]
      def bullet_train_model_segments(name)
        string = case name
        when String, Symbol
          name.to_s
        else
          name.respond_to?(:name) ? name.name.to_s : ""
        end

        segments = string.delete_prefix("::").underscore.split("/")

        if segments.empty? || segments.any?(&:empty?)
          raise ArgumentError, "`model` couldn't make a route out of #{name.inspect}. Pass a model name like \"Projects::Deliverable\", a symbol like :deliverable, or the model class itself."
        end

        segments
      end

      def bullet_train_draw_model(segments, options, parent, &block)
        namespaces = segments[0..-2]
        collection = segments.last.pluralize.to_sym

        # Children declared inside `block` are collected here and drawn after the block
        # closes, so their member routes land outside this model's `resources` block.
        children = []
        resource_block = proc do
          outer_pending, outer_scope = bullet_train_pending_models, @bullet_train_block_scope
          @bullet_train_pending_models = children
          @bullet_train_block_scope = @scope

          begin
            block&.call
          ensure
            @bullet_train_pending_models = outer_pending
            @bullet_train_block_scope = outer_scope
          end
        end

        if parent
          bullet_train_draw_nested(namespaces, collection, options, parent, &resource_block)
        else
          bullet_train_namespaces(namespaces) do
            resources collection, **options, &resource_block
          end
        end

        return if children.empty?

        me = {namespaces: namespaces, collection: collection, options: options}
        children.each do |(child_name, child_options, child_block)|
          bullet_train_draw_model(bullet_train_model_segments(child_name), child_options || {}, me, &child_block)
        end
      end

      # Draws a child model under its parent's canonical path. The parent is reopened with
      # `only: []` so nesting adds no duplicate routes of its own.
      def bullet_train_draw_nested(namespaces, collection, options, parent, &resource_block)
        # Namespaces the parent and child share are drawn as real namespaces, so names and
        # params read the way the hand-written Rails equivalent would.
        # E.g. `Hosting::Site` + `Hosting::Page` nest under `:site_id`, not `:hosting_site_id`.
        shared = bullet_train_common_prefix(parent[:namespaces], namespaces)
        parent_segments = parent[:namespaces][shared.size..] + [parent[:collection].to_s]
        child_segments = namespaces[shared.size..]

        # Leading child namespaces the parent's own path already spells out contribute the
        # child's module and shallow path, but must not be repeated in the nested path.
        # E.g. `Project` + `Projects::Deliverable` nest at `/projects/:project_id/deliverables`.
        implied = bullet_train_common_prefix(parent_segments, child_segments)
        nested = child_segments[implied.size..]

        nesting_name, nesting_options = bullet_train_nesting_arguments(parent_segments, parent[:options])

        bullet_train_namespaces(shared) do
          resources nesting_name, **nesting_options do
            bullet_train_implied_scope(implied) do
              bullet_train_namespaces(nested) do
                resources collection, shallow: true, **options, &resource_block
              end
            end
          end
        end
      end

      # Reopens the parent resource purely as a place to nest. Only the options that decide
      # the child's URL shape are carried over; the parent's own routes were already drawn.
      def bullet_train_nesting_arguments(parent_segments, parent_options)
        leading = parent_segments[0..-2]
        last = parent_segments.last

        path = leading + [parent_options[:path]&.to_s || last]
        # `shallow: false` keeps an ambient `shallow` scope — e.g. a `shallow do` block around the
        # whole route file — from applying Rails' shallow path to the nesting itself, which would
        # prepend the child's shallow path to its nested path a second time. The child re-enables
        # `shallow` for its own routes.
        options = {path: path.join("/"), only: [], shallow: false}
        options[:param] = parent_options[:param] if parent_options[:param]
        options[:as] = (leading + [parent_options[:as].to_s]).join("_") if parent_options[:as]

        [parent_segments.join("_").to_sym, options]
      end

      def bullet_train_implied_scope(implied, &block)
        return yield if implied.empty?

        scope(
          module: implied.join("/"),
          shallow_path: implied.join("/"),
          shallow_prefix: implied.join("_"),
          &block
        )
      end

      def bullet_train_namespaces(names, &block)
        return yield if names.empty?

        namespace names.first do
          bullet_train_namespaces(names[1..], &block)
        end
      end

      def bullet_train_common_prefix(first, second)
        prefix = []

        first.each_with_index do |segment, index|
          break unless second[index] == segment
          prefix << segment
        end

        prefix
      end
    end
  end
end
