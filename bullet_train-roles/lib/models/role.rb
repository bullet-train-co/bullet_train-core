# frozen_string_literal: true

require "active_hash"

class Role < ActiveYaml::Base
  include ActiveYaml::Aliases
  set_root_path "config/models"
  set_filename "roles"

  field :includes, default: []
  field :models, default: []
  field :manageable_roles, default: []

  def self.admin
    find_by_key("admin")
  end

  def self.default
    find_by_key("default")
  end

  # Allow us to use either symbols or strings when searching
  def self.find_by_key(key)
    super(key.to_s)
  end

  def self.includes(role_or_key)
    role_key = role_or_key.is_a?(Role) ? role_or_key.key : role_or_key.to_s
    role = Role.find_by_key(role_key)
    return [] if role.nil?
    return Role.all.select(&:assignable?) if role.default?
    result = []
    all.each do |role|
      result << role if role.includes.include?(role_key)
    end
    result
  end

  def self.assignable
    all.reject(&:default?)
  end

  def self.find(key)
    all.find { |role| role.key == key.to_s }
  end

  # We don't want to ever use the automatically generated ids from ActiveYaml.  These are created based on the order of objects in the yml file
  # so if someone ever changed the order of that file around, they would really mess up the user permissions. Instead, we're using the key attribute.
  def id
    key
  end

  def to_s
    key
  end

  def included_by
    Role.includes(self)
  end

  # We need to search for memberships that have this role included directly OR any memberships that have this role _through_ it being included in another role they have
  def key_plus_included_by_keys
    # get direct parent roles
    (included_by.map(&:key_plus_included_by_keys).flatten + [id]).uniq
  end

  def default?
    key == "default"
  end

  def admin?
    key == "admin"
  end

  def included_roles
    default_roles = []
    default_roles << Role.default unless default?
    (default_roles + includes.map { |included_key| Role.find_by_key(included_key) }).uniq.compact
  end

  def manageable_by?(role_or_roles)
    return true if default?
    roles = role_or_roles.is_a?(Array) ? role_or_roles : [role_or_roles]
    roles.each do |role|
      return true if role.manageable_roles.include?(key)
      role.included_roles.each do |included_role|
        return true if manageable_by?([included_role])
      end
    end

    false
  end

  def assignable?
    !default?
  end

  def ability_generator(user, through, parent, intermediary)
    models.each do |model_name, _|
      ag = AbilityGenerator.new(self, model_name, user, through, parent, intermediary)
      yield(ag)
    end
  end

  # The only purpose of this class is to allow developers to do things like:
  # Membership.first.roles << Role.admin
  # Membership.first.roles.delete Role.admin
  # It basically makes the role_ids column act like a Rails `has_many through` collection - this includes automatically saving changes when you add or remove from the array.
  class Collection < Array
    def initialize(model, ary)
      @model = model
      super(ary)
    end

    def <<(role)
      return true if include?(role)
      role_ids = @model.role_ids || []
      role_ids << role.id
      @model.update(role_ids: role_ids)
    end

    def delete(role)
      return @model.save unless include?(role)
      current_role_ids = @model.role_ids || []
      new_role_ids = current_role_ids - [role.key]
      @model.role_ids = new_role_ids
      @model.save
    end
  end

  class AbilityGenerator
    attr_reader :model

    def initialize(role, model_name, user, through, parent_name, intermediary = nil)
      begin
        @model = model_name.constantize
      rescue NameError
        raise "#{model_name} model is used in `config/models/roles.yml` for the #{role.key} role but is not defined in `app/models`."
      end

      @role = role
      @ability_data = role.models[model_name]
      @through = through
      @parent = user.send(through).reflect_on_association(parent_name)&.klass
      @parent_ids = user.parent_ids_for(@role, @through, parent_name) if @parent
      @intermediary = intermediary
      @intermediary_class = @model.reflect_on_association(intermediary)&.class_name&.constantize if @intermediary.present?
    end

    def valid?
      actions.present? && model.present? && condition.present?
    end

    def actions
      return @actions if @actions
      @actions = (@ability_data["actions"] if @ability_data.is_a?(Hash)) || @ability_data
      # crud is a special value that we substitute for the 4 crud actions
      # This is instead of :manage which covers all 4 actions _and_ any extra actions the controller may respond to
      @actions = crud_actions if @actions.to_s.downcase == "crud"
      @actions = [actions] unless actions.is_a?(Array)
      @actions.map!(&:to_sym)
    end

    def crud_actions
      [:create, :read, :update, :destroy]
    end

    def possible_parent_associations
      ary = @parent.to_s.split("::").map(&:underscore)
      possibilities = []
      current = nil
      until ary.empty?
        current = "#{ary.pop}#{"_" unless current.nil?}#{current}"
        possibilities << current
      end
      possibilities.map(&:to_sym)
    end

    def condition
      return @condition if @condition
      return nil unless @parent_ids
      if @model == @parent
        return @condition = {id: @parent_ids}
      end
      parent_association = possible_parent_associations.find { |association| @model.reflect_on_association(association) || @intermediary_class&.reflect_on_association(association) }
      return nil unless parent_association.present?
      # If possible, use the team_id attribute because it saves us having to join all the way back to the source parent model
      # In some scenarios this may be quicker, or if the parent model is in a different database shard, it may not even
      # be possible to do the join
      parent_with_id = "#{parent_association}_id"
      @condition = if @model.column_names.include?(parent_with_id)
        {parent_with_id.to_sym => @parent_ids}
      elsif @intermediary.present? && @model.reflect_on_association(@intermediary)
        {@intermediary.to_sym => {parent_with_id.to_sym => @parent_ids}}
      else
        {parent_association => {id: @parent_ids}}
      end
    end
  end
end
