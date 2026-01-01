require_relative "callbacks_instrumentation/backport"

module ActiveSupport::Callbacks
  ClassMethods.prepend Module.new {
    def set_callback(name, *filter_list, &block)
      *, options = normalize_callback_params(filter_list.dup, block)
      Instrumenter.options = options.merge(caller_locations:)
      super
    ensure
      Instrumenter.options = nil
    end
  }

  Callback.prepend Module.new {
    def compiled
      @compiled = super.then { Instrumenter.build self, _1 } unless defined?(@compiled)
      @compiled
    end
  }

  class Instrumenter < Data.define(:callback, :callable, :options)
    singleton_class.attr_accessor :options

    def self.build(callback, callable)
      options ? new(callback, callable, options) : callable
    end

    def initialize(callback:, callable:, options:)
      caller_locations = options.delete(:caller_locations)
      @location = Rails.backtrace_cleaner.clean(caller_locations.map(&:to_s)).first if caller_locations
      @full_name = (callback.name == :commit) ? caller_locations.first.base_label : "#{callback.kind}_#{callback.name}"
      super
    end
    attr_reader :options, :location, :full_name
    delegate :name, :kind, :filter, to: :callback

    def apply(sequence)
      case kind
      in :before then sequence.before(self)
      in :after then sequence.after(self)
      in :around then sequence.around(self)
      end
    end

    def call(env)
      ActiveSupport::Notifications.instrument "callback.active_support", callback: self do
        callable.call(env)
      end
    end
  end

  class LogSubscriber < ActiveSupport::LogSubscriber
    attach_to :active_support

    def callback(event)
      event.payload => {callback:}
      info { "Callback #{callback.full_name}: #{callback.filter} #{callback.options} from #{callback.location}".squish }
    end
  end
end
