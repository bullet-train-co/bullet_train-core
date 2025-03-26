return if ActiveSupport::VERSION.to_s.start_with?("7.2")

# Backports a few commits from Rails 7.2 to make our debugging extension easier:
#
# - https://github.com/rails/rails/commit/6c5a042824fdaf630ebaa7fb293b8c2543f20d00
# - https://github.com/rails/rails/commit/42ad4d6b0bfc14e16050f9945a8b2ac5c87c294f
module ActiveSupport::Callbacks
  Callback.prepend Module.new {
    def initialize(...)
      super
      compiled # Eager load ActiveSupport::Callback procs
    end

    def compiled
      @compiled ||=
        begin
          user_conditions = conditions_lambdas
          user_callback = CallTemplate.build(@filter, self)

          case kind
          when :before
            Filters::Before.new(user_callback.make_lambda, user_conditions, chain_config, @filter, name)
          when :after
            Filters::After.new(user_callback.make_lambda, user_conditions, chain_config)
          when :around
            Filters::Around.new(user_callback, user_conditions)
          end
        end
    end

    def apply(callback_sequence)
      compiled.apply(callback_sequence)
    end
  }

  class CallbackSequence
    def before(before)
      @before.unshift(before)
      self
    end

    def after(after)
      @after.push(after)
      self
    end
  end

  module Filters
    # Around wasn't defined before our commit backport, so we don't need to remove that.
    remove_const :Before
    remove_const :After

    class Before
      def initialize(user_callback, user_conditions, chain_config, filter, name)
        halted_lambda = chain_config[:terminator]
        @user_callback, @user_conditions, @halted_lambda, @filter, @name = user_callback, user_conditions, halted_lambda, filter, name
        freeze
      end
      attr_reader :user_callback, :user_conditions, :halted_lambda, :filter, :name

      def call(env)
        target = env.target
        value = env.value
        halted = env.halted

        if !halted && user_conditions.all? { |c| c.call(target, value) }
          result_lambda = -> { user_callback.call target, value }
          env.halted = halted_lambda.call(target, result_lambda)
          if env.halted
            target.send :halted_callback_hook, filter, name
          end
        end

        env
      end

      def apply(callback_sequence)
        callback_sequence.before(self)
      end
    end

    class After
      attr_reader :user_callback, :user_conditions, :halting
      def initialize(user_callback, user_conditions, chain_config)
        halting = chain_config[:skip_after_callbacks_if_terminated]
        @user_callback, @user_conditions, @halting = user_callback, user_conditions, halting
        freeze
      end

      def call(env)
        target = env.target
        value = env.value
        halted = env.halted

        if (!halted || !@halting) && user_conditions.all? { |c| c.call(target, value) }
          user_callback.call target, value
        end

        env
      end

      def apply(callback_sequence)
        callback_sequence.after(self)
      end
    end

    class Around
      def initialize(user_callback, user_conditions)
        @user_callback, @user_conditions = user_callback, user_conditions
        freeze
      end

      def apply(callback_sequence)
        callback_sequence.around(@user_callback, @user_conditions)
      end
    end
  end
end
