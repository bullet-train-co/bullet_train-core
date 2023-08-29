require "bullet_train/outgoing_webhooks/version"
require "bullet_train/outgoing_webhooks/engine"

module BulletTrain
  module OutgoingWebhooks
    def self.default_for(klass, method, default_value)
      klass.respond_to?(method) ? klass.send(method) || default_value : default_value
    end

    mattr_accessor :parent_class, default: default_for(BulletTrain, :parent_class, "Team")
    mattr_accessor :base_class, default: default_for(BulletTrain, :base_class, "ApplicationRecord")
    mattr_accessor :advanced_hostname_security, default: false
    mattr_accessor :http_verify_mode

    def self.parent_association
      parent_class.underscore.to_sym
    end

    def self.parent_resource
      parent_class.underscore.pluralize.to_sym
    end

    def self.parent_class_specified?
      parent_class != "Team"
    end

    def self.current_parent_method
      "current_#{parent_association}"
    end

    def self.parent_association_id
      "#{parent_association}_id".to_sym
    end
  end
end
