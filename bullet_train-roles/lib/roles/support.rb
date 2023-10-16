# frozen_string_literal: true

require "active_support"

module Roles
  module Support
    extend ActiveSupport::Concern

    class_methods do
      def roles_only(*roles)
        @allowed_roles = roles.map(&:to_sym)
      end

      def assignable_roles
        return Role.assignable if @allowed_roles.nil?
        Role.assignable.select { |role| @allowed_roles.include?(role.key.to_sym) }
      end

      # Note default_role is an ActiveRecord core class method so we need to use something else here
      def default_roles
        default_role = Role.default
        return [default_role] if @allowed_roles.nil?
        @allowed_roles.include?(default_role.key.to_sym) ? [default_role] : []
      end
    end

    included do
      validate :validate_roles

      # This query will return roles that include the given role.  See self.with_roles below for details
      scope :with_role, ->(role) { role.nil? ? all : with_roles([role]) }
      scope :viewers, -> { where("#{table_name}.role_ids = ?", [].to_json) }
      scope :editors, -> { with_role(Role.find_by_key("editor")) }
      scope :admins, -> { with_role(Role.find_by_key("admin")) }

      after_save :invalidate_cache
      after_destroy :invalidate_cache

      # This query will return records that have a role "included" in a different role they have.
      # For example, if you do with_roles(editor) it will return admin users if the admin role includes the editor role
      def self.with_roles(roles)
        # Mysql and postgres have different syntax for searching json or jsonb columns so we need different queries depending on the database
        mysql? ? with_roles_mysql(roles) : with_roles_postgres(roles)
      end

      def self.with_roles_mysql(roles)
        queries = []
        roles.map(&:key_plus_included_by_keys).flatten.uniq.map(&:to_s).each do |role|
          queries << "JSON_CONTAINS(#{table_name}.role_ids, '\"#{role}\"')"
        end
        query = queries.join(" OR ")
        where(query)
      end

      def self.with_roles_postgres(roles)
        where("#{table_name}.role_ids ?| array[:keys]", keys: roles.map(&:key_plus_included_by_keys).flatten.uniq.map(&:to_s))
      end

      def self.mysql?
        ["mysql", "trilogy"].any? { |adapter| ActiveRecord::Base.connection.adapter_name.downcase.include?(adapter) }
      end

      def validate_roles
        self.role_ids = role_ids&.select(&:present?) || []

        return if @allowed_roles.nil?

        roles.each do |role|
          errors.add(:roles, :invalid) unless @allowed_roles.include?(role.key.to_sym)
        end
      end

      def roles
        Role::Collection.new(self, (self.class.default_roles + roles_without_defaults).compact.uniq)
      end

      # Tests if the user can perform a given role
      # They can have the role assigned directly, or the role can be included in another role they have
      def can_perform_role?(role_or_key)
        role_key = role_or_key.is_a?(Role) ? role_or_key.key : role_or_key
        role = Role.find_by_key(role_key)
        return true if roles.include?(role)
        # Check all the roles that this role is included into
        Role.includes(role_key).each do |included_in_role|
          return true if roles.include?(included_in_role)
          return true if can_perform_role?(included_in_role)
        end
        false
      end

      def roles=(roles)
        update(role_ids: roles.map(&:key))
      end

      def assignable_roles
        roles.select(&:assignable?)
      end

      def roles_without_defaults
        role_ids&.map { |role_id| Role.find(role_id) } || []
      end

      def manageable_roles
        roles.map(&:manageable_roles).flatten.uniq.map { |role_key| Role.find_by_key(role_key) }
      end

      def can_manage_role?(role)
        manageable_roles.include?(role)
      end

      def admin?
        roles.select(&:admin?).any?
      end

      def invalidate_cache
        user&.invalidate_ability_cache
      end
    end
  end
end
