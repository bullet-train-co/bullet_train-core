# frozen_string_literal: true

require "test_helper"
require "cancan"

class PermitTest < ActiveSupport::TestCase
  class ClassMethodsTest < ActiveSupport::TestCase
    class TestAbility
      include ::CanCan::Ability
      include ::Roles::Permit
      def initialize(user)
      end
    end

    setup do
      @admin_user = FactoryBot.create :onboarded_user
      @admin_user.memberships.first.update!(role_ids: ["admin", "editor"])
      @test_ability = TestAbility.new(@admin_user)
    end

    test "Permit#assign_permissions assigns a new permission" do
      permissions = []
      permissions << {
        actions: :download,
        model: "User",
        condition: :all
      }
      can_count = @test_ability.permissions[:can].count
      @test_ability.assign_permissions(permissions)
      assert_equal @test_ability.permissions[:can].count, can_count + 1
    end

    test "Permit#build_permissions returns an array of Hashes" do
      assert @test_ability.build_permissions(@admin_user, :memberships, :team, nil, []).is_a?(Array)
      assert @test_ability.build_permissions(@admin_user, :memberships, :team, nil, []).first.is_a?(Hash)
    end

    test "When providing a cache_key the permissions are stored in the cache" do
      Rails.cache = ActiveSupport::Cache.lookup_store(:memory_store)
      Rails.cache.clear
      assert Rails.cache.instance_variable_get(:@data).keys.none?
      @test_ability.permit(@admin_user, through: :memberships, parent: :team, rails_cache_key: "my_cache_key")
      assert Rails.cache.fetch("my_cache_key").present?
      assert_equal 1, Rails.cache.instance_variable_get(:@data).keys.count
    end

    test "When the cache_key is not provided, it is not saved to the rails cache" do
      Rails.cache = ActiveSupport::Cache.lookup_store(:memory_store)
      Rails.cache.clear
      assert Rails.cache.instance_variable_get(:@data).keys.none?
      @test_ability.permit(@admin_user, through: :memberships, parent: :team, rails_cache_key: nil)
      assert Rails.cache.instance_variable_get(:@data).keys.none?
    end

    test "When included_roles are provided, only those roles are included in the permissions" do
      @test_ability.permit(@admin_user, through: :memberships, parent: :team, included_roles: [Role.find_by_key("editor")])

      refute @test_ability.can?(:manage, Team)
      assert @test_ability.can?(:update, Scaffolding::AbsolutelyAbstract::CreativeConcept)
    end

    test "When included_roles is not provided, all roles are included in the permissions" do
      @test_ability.permit(@admin_user, through: :memberships, parent: :team)

      assert @test_ability.can?(:manage, Team)
    end
  end
end
