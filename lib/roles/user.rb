# frozen_string_literal: true

require "active_support"

module Roles
  module User
    extend ActiveSupport::Concern

    included do
      def parent_ids_for(role, through, parent)
        parent_id_column = "#{parent}_id"
        key = "#{role.key}_#{through}_#{parent_id_column}s"
        # TODO Maybe we should make ability caching a default feature of the gem?
        # If we do that, we would just make it check whether `ability_cache` exists.
        # return ability_cache[key] if ability_cache && ability_cache[key]
        role = nil if role.default?
        value = send(through).with_role(role).distinct.pluck(parent_id_column)
        # TODO Maybe we should make ability caching a default feature of the gem?
        # current_cache = ability_cache || {}
        # current_cache[key] = value
        # update_column :ability_cache, current_cache
        value
      end
    end
  end
end
