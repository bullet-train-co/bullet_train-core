# frozen_string_literal: true

module Roles
  module Permit
    def permit(user, through:, parent:, debug: false, intermediary: nil, rails_cache_key: nil)
      # When changing permissions during development, you may also want to do this on each request:
      # User.update_all ability_cache: nil if Rails.env.development?
      permissions = if rails_cache_key
        Rails.cache.fetch(rails_cache_key) do
          build_permissions(user, through, parent, intermediary)
        end
      else
        build_permissions(user, through, parent, intermediary)
      end

      begin
        assign_permissions(permissions)
      rescue NameError => e
        if rails_cache_key
          # Cache has become stale with model classes that no longer exist
          Rails.logger.info "Found missing models in cache - #{e.message.squish} - building fresh permissions"
          Rails.cache.delete(rails_cache_key)
          permissions = build_permissions(user, through, parent, intermediary)
          assign_permissions(permissions)
        else
          raise e
        end
      end

      if debug
        puts "###########################"
        puts "Auto generated `ability.rb` content:"
        permissions.map do |permission|
          if permission[:is_debug]
            puts permission[:info]
          else
            puts "can #{permission[:actions]}, #{permission[:model]}, #{permission[:condition]}"
          end
        end
        puts "############################"
      end
    end

    def assign_permissions(permissions)
      permissions.each do |permission|
        can(permission[:actions], permission[:model].constantize, permission[:condition]) unless permission[:is_debug]
      end
    end

    def build_permissions(user, through, parent, intermediary)
      added_roles = Set.new
      permissions = []
      user.send(through).map(&:roles).flatten.uniq.each do |role|
        unless added_roles.include?(role)
          permissions << {is_debug: true, info: "########### ROLE: #{role.key}"}
          permissions += add_abilities_for(role, user, through, parent, intermediary)
          added_roles << role
        end

        role.included_roles.each do |included_role|
          unless added_roles.include?(included_role)
            permissions << {is_debug: true, info: "############# INCLUDED ROLE: #{included_role.key}"}
            permissions += add_abilities_for(included_role, user, through, parent, intermediary)
          end
        end
      end

      permissions
    end

    def add_abilities_for(role, user, through, parent, intermediary)
      permissions = []
      role.ability_generator(user, through, parent, intermediary) do |ag|
        permissions << if ag.valid?
          {is_debug: false, actions: ag.actions, model: ag.model.to_s, condition: ag.condition}
        else
          {is_debug: true, info: "# #{ag.model} does not respond to #{parent} so we're not going to add an ability for the #{through} context"}
        end
      end
      permissions
    end
  end
end
