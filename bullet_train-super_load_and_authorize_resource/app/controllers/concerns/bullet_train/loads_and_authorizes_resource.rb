module BulletTrain::LoadsAndAuthorizesResource
  extend ActiveSupport::Concern

  class_methods do
    # Returns an array of module names based on the classes namespace minus regex_to_remove_controller_namespace
    def model_namespace_from_controller_namespace
      name
        .gsub(regex_to_remove_controller_namespace || //, "")
        .split("::")
        .tap(&:pop) # drops actual class name
    end

    def regex_to_remove_controller_namespace
      return super if defined?(super)

      raise "This is a template method that needs to be implemented by controllers including LoadsAndAuthorizesResource."
    end

    # this is one of the few pieces of 'magical' functionality that bullet train implements
    # for you in your controllers beyond that is provided by the underlying gems that we've
    # tied together. we've taken the liberty of doing this because it's heavily based on
    # cancancan's `load_and_authorize_resource` method, which is awesome, but it also
    # implements a lot of the options required to make that method work very well for our
    # controllers in the account namespace, including our shallow nested routes.
    #
    # there are also some complications that were introduced into this method by our support
    # for namespaced models and controllers. (we introduced this complexity in support of
    # namespacing our `Oauth::` models and controllers.)
    #
    # to help you understand the code below, usually `through` is `team`
    # and `model` is something like `project`.
    def account_load_and_authorize_resource(model, positional_through = nil, through: positional_through, collection_actions: [], member_actions: [], except: [], **options)
      # options are now required, because you have to have at least a 'through' setting.

      # we used to support calling this method with a signature like this:
      #
      #   `account_load_and_authorize_resource [:oauth, :twitter_account], :team`
      #
      # however this abstraction was too short-sighted so we've updated this method to accept the exact same method
      # signature as cancancan's original `load_and_authorize_resource` method.
      if model.is_a?(Array)
        raise "Bullet Train has depreciated this method of calling `account_load_and_authorize_resource`. Read the comments on this line of source for more details."
      end

      # fetch the namespace of the controller. this should generally match the namespace of the model, except for the
      # `account` part.
      namespace = model_namespace_from_controller_namespace

      model_class_names = namespace.size.downto(0).map do
        [*namespace, model.to_s.classify].join("::").tap { namespace.pop }
      end

      model_class = model_class_names.find(&:safe_constantize)&.safe_constantize
      unless model_class
        raise "Your 'account_load_and_authorize_resource' is broken. We tried #{model_class_names.join(" and ")}, but didn't find a valid class name."
      end

      through_as_symbols = Array(through)
      through_class_names = through_as_symbols.map do |through_as_symbol|
        # reflect on the belongs_to association of the child model to figure out the class names of the parents.
        association = model_class.reflect_on_association(through_as_symbol)
        unless association
          raise "Your 'account_load_and_authorize_resource' is broken. Tried to reflect on the `#{through_as_symbol}` association of #{model_class_names}, but didn't find one."
        end

        association.klass.name
      end

      if through_as_symbols.count > 1 && !options[:polymorphic]
        raise "When a resource can be loaded through multiple parents, please specify the 'polymorphic' option to tell us what that controller calls the parent, e.g. `polymorphic: :imageable`."
      end

      instance_variable_name = "@#{options[:polymorphic] || through_as_symbols.first}"

      # `collection_actions:` and `member_actions:` provide support for shallow nested resources, which
      # keep our routes tidy even after many levels of nesting. most people
      # i talk to don't actually know about this feature in rails, but it's
      # actually the recommended approach in the rails routing documentation.
      #
      # also, similar to `load_and_authorize_resource`, people can pass in additional
      # actions for which the resource should be loaded, but because we're making
      # separate calls to `load_and_authorize_resource` for member and collection
      # actions, we ask controllers to specify these actions separately, e.g.:
      #   `account_load_and_authorize_resource :invitation, :team, member_actions: [:accept, :promote]`
      #
      # `except:` is native to cancancan and allows you to skip account_load_and_authorize_resource
      # for a specific action that would otherwise run it (e.g. see invitations#show.)
      collection_actions = (%i[index new create reorder] + collection_actions) - except
      member_actions = (%i[show edit update destroy] + member_actions) - except

      # NOTE: because we're using prepend for all of these, these are written in backwards order
      # of how they'll be executed during a request!

      # 4. finally, load the team and parent resource if we can.
      prepend_before_action :load_team

      # x. this and the thing below it are only here to make a sortable concern possible.
      prepend_before_action only: member_actions do
        @child_object = instance_variable_get(:"@#{model}")
        @parent_object = instance_variable_get instance_variable_name
      end

      prepend_before_action only: collection_actions do
        @parent_object = instance_variable_get instance_variable_name
        @child_collection = options[:through_association].presence&.to_sym || model.to_s.pluralize.to_sym
      end

      prepend_before_action only: member_actions do
        model_instance = instance_variable_get(:"@#{model}")
        if model_instance && !instance_variable_defined?(instance_variable_name)
          parent = through_as_symbols.lazy.filter_map { model_instance.public_send(_1) }.first
          instance_variable_set instance_variable_name, parent
        end
      end

      if options[:polymorphic]
        prepend_before_action only: collection_actions do
          unless instance_variable_defined?(:"@#{options[:polymorphic]}")
            parent = through_as_symbols.lazy.filter_map { instance_variable_get :"@#{_1}" }.first
            instance_variable_set :"@#{options[:polymorphic]}", parent
          end
        end
      end

      # 3. on action resource, we have a specific id for the child resource, so load it directly.
      load_and_authorize_resource model,
        options.merge(
          class: model_class.name,
          only: member_actions,
          prepend: true,
          shallow: true
        )

      # 2. only load the child resource through the parent resource for collection actions.
      load_and_authorize_resource model,
        options.merge(
          class: model_class.name,
          through: through_as_symbols,
          only: collection_actions,
          prepend: true,
          shallow: true
        )

      # 1. load the parent resource for collection actions only. (we're using shallow routes.)
      # since a controller can have multiple potential parents, we have to run this as a loop on every possible
      # parent. (the vast majority of controllers only have one parent.)

      through_class_names.each_with_index do |through_class_name, index|
        load_and_authorize_resource through_as_symbols[index],
          options.merge(
            class: through_class_name,
            only: collection_actions,
            prepend: true,
            shallow: true
          )
      end
    end
  end

  def load_team
    @team ||= @child_object&.try(:team) || @parent_object&.try(:team)

    return unless @team

    if defined?(Current) && Current.respond_to?(:team=)
      Current.team = @team
    end

    # If the currently loaded team is saved to the database, make that the user's new current team.
    if @team.try(:persisted?)
      if can? :show, @team
        current_user.update_column(:current_team_id, @team.id)
      end
    end
  end

  # These are methods that `account_load_and_authorize_resource` assumes will be present on any controllers
  # that call that method. In order to use the new Rails default for `config.raise_on_missing_callback_actions = true`
  # we need to have these methods defined on any controller that includes this module. We define them here so
  # that they will exist at the time that `account_load_and_authorize_resource` is called. We assume that controllers
  # will implement real versions of these methods (if needed) to override these dummy methods. We raise, instead of
  # just defining empty methods, so that if these methods are ever reached it will be more obvious what's happening
  # that it would be if an empty method were called and it appears that nothing happens.
  def reorder
    raise "This is a template method that needs to be implemented by controllers including LoadsAndAuthorizesResource."
  end

  def new
    raise "This is a template method that needs to be implemented by controllers including LoadsAndAuthorizesResource."
  end

  def edit
    raise "This is a template method that needs to be implemented by controllers including LoadsAndAuthorizesResource."
  end

  def create
    raise "This is a template method that needs to be implemented by controllers including LoadsAndAuthorizesResource."
  end

  def update
    raise "This is a template method that needs to be implemented by controllers including LoadsAndAuthorizesResource."
  end
end
