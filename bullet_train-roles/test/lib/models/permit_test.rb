# frozen_string_literal: true

require "test_helper"

class PermitTest < ActiveSupport::TestCase
  class ClassMethodsTest < ActiveSupport::TestCase
    setup do
      @admin_user = FactoryBot.create :onboarded_user
      @admin_ability = Ability.new(@admin_user)
    end

    test "Permit#assign_permissions assigns a new permission" do
      permissions = []
      permissions << {
        actions: :download,
        model: "User",
        condition: :all
      }
      can_count = @admin_ability.permissions[:can].count
      @admin_ability.assign_permissions(permissions)
      assert_equal @admin_ability.permissions[:can].count, can_count + 1
      assert_equal @admin_ability.permissions[:can].count, 10
    end

    test "Permit#build_permissions returns an array of Hashes" do
      assert @admin_ability.build_permissions(@admin_user, :memberships, :team, nil).is_a?(Array)
      assert @admin_ability.build_permissions(@admin_user, :memberships, :team, nil).first.is_a?(Hash)
    end

    test "When providing a cache_key the permissions are stored in the cache" do
      Rails.cache = ActiveSupport::Cache.lookup_store(:memory_store)
      Rails.cache.clear
      assert Rails.cache.instance_variable_get(:@data).keys.none?
      @admin_ability.permit(@admin_user, through: :memberships, parent: :team, rails_cache_key: "my_cache_key")
      assert Rails.cache.fetch("my_cache_key").present?
      assert_equal 1, Rails.cache.instance_variable_get(:@data).keys.count
    end

    test "When the cache_key is not provided, it is not saved to the rails cache" do
      Rails.cache = ActiveSupport::Cache.lookup_store(:memory_store)
      Rails.cache.clear
      assert Rails.cache.instance_variable_get(:@data).keys.none?
      @admin_ability.permit(@admin_user, through: :memberships, parent: :team, rails_cache_key: nil)
      assert Rails.cache.instance_variable_get(:@data).keys.none?
    end
  end
end
