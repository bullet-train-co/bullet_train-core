# frozen_string_literal: true

require "test_helper"

class RoleTest < ActiveSupport::TestCase
  class ClassMethodsTest < ActiveSupport::TestCase
    def setup
      @admin_user = FactoryBot.create :onboarded_user
      @membership = FactoryBot.create :membership, user: @admin_user, team: @admin_user.current_team, role_ids: [Role.admin.id]
      @document = FactoryBot.create :document, membership: @membership
      @admin_ability = Ability.new(@admin_user)
      @parent_ids = [2, 3]
    end

    test "Role.admin return the correct role" do
      assert_equal Role.admin, Role.find_by_key("admin")
    end

    test "Role.default returns the default role" do
      assert_equal Role.default, Role.find_by_key("default")
    end

    test "Role.includes(default) should return all other roles" do
      assert_equal Role.all.count - 1, Role.includes(Role.default).count
    end

    test "Role.includes works when given a string" do
      assert Role.includes("editor").include?(Role.admin)
    end

    test "Role.include works when given a role" do
      assert Role.includes(Role.find_by_key("editor")).include? Role.admin
    end

    test "Role.assignable should not return the default role" do
      refute_includes Role.assignable, Role.default
    end

    test "Role.assignable should include the admin role" do
      assert_includes Role.assignable, Role.admin
    end
  end

  class InstanceMethodsTest < ActiveSupport::TestCase
    def setup
      @admin_user = FactoryBot.create :onboarded_user
      @membership = FactoryBot.create :membership, user: @admin_user, team: @admin_user.current_team, role_ids: [Role.admin.id]
      @non_admin_user = FactoryBot.create :onboarded_user
      @non_admin_membership = FactoryBot.create :membership, user: @non_admin_user, team: @non_admin_user.current_team, role_ids: [Role.find(:editor).id]
    end

    test "default_role#included_by returns the admin role" do
      assert_includes Role.default.included_by, Role.admin
    end

    test "editor_role#included_by returns the admin role" do
      assert_includes Role.find_by_key("editor").included_by, Role.admin
    end

    test "editor_role#included_by does not include the default role" do
      refute_includes Role.find_by_key("editor").included_by, Role.default
    end

    test "admin_role#key_plus_included_by_keys returns only the admin role id" do
      expected_role_ids = [Role.admin.id]
      assert_equal Role.admin.key_plus_included_by_keys, expected_role_ids
    end

    test "default_role#key_plus_included_by_keys returns all role ids" do
      expected_role_ids = Role.all.map(&:id)
      assert_empty expected_role_ids - Role.default.key_plus_included_by_keys
    end

    test "default? returns true for the default role" do
      assert Role.default.default?
    end

    test "default? returns false for non default roles" do
      refute Role.admin.default?
    end

    test "admin? returns true for the admin role" do
      assert Role.admin.admin?
    end

    test "admin? returns false for a non admin role" do
      refute Role.default.admin?
    end

    test "admin_role.included_roles includes the default role" do
      assert_includes Role.admin.included_roles, Role.default
    end

    test "admin_role.included_roles includes the editor role" do
      assert_includes Role.admin.included_roles, Role.find_by_key("editor")
    end

    test "default.manageable_by?(admin_role) returns true" do
      assert Role.default.manageable_by?([Role.admin])
    end

    test "admin_role.manageable_by?(default_role) returns false" do
      refute Role.admin.manageable_by?([Role.default])
    end

    test "deleting a role removes it from the role_ids column" do
      assert @membership.roles.include?(Role.admin)
      @membership.roles.delete(Role.admin)
      refute @membership.role_ids.include?(Role.admin.id)
    end

    test "Adding a role adds it to the role_ids column" do
      editor_role = Role.find_by_key "editor"
      refute @membership.roles.include?(editor_role)
      @membership.roles << editor_role
      @membership.reload
      assert @membership.roles.include?(editor_role)
    end

    test "When role_ids is nil, we can add a new role" do
      @membership.update_column(:role_ids, nil)
      @membership.roles << Role.admin
      assert @membership.admin?
    end

    test "When role_ids is nil, we can attempt to delete a role without error" do
      @membership.update_column(:role_ids, nil)
      @membership.roles.delete(Role.admin)
      assert_empty @membership.role_ids
    end

    test "Calling #roles when role_ids is nil returns the default role only" do
      @membership.update_column(:role_ids, nil)
      assert_equal @membership.roles, [Role.find_by_key("default")]
    end

    test "#can_perform_role? returns true if the user has been assigned the role" do
      assert @membership.can_perform_role?(Role.admin)
    end

    test "#can_perform_role? returns true if the user has not been assigned the role, but it is included in another role they have" do
      assert @membership.roles.include? Role.admin
      refute @membership.roles.include?(Role.find(:editor))
      assert Role.admin.includes.include?("editor")
      assert @membership.can_perform_role?(:editor)
    end

    test "#can_perform_role? returns false if the user has not been assigned the role, and it is not included in another role they have" do
      assert @non_admin_membership.roles.include?(Role.find(:editor))
      refute Role.find(:editor).includes.include?("crud_role")
      assert Role.find :crud_role
      refute @non_admin_membership.can_perform_role?(:crud_role)
    end

    test "#can_perform_role? returns true if the role being tested is 2 layers deep" do
      # supervisor includes manager, which includes editor
      @supervisor_membership = FactoryBot.create :membership, user: @admin_user, team: @admin_user.current_team, role_ids: []
      refute @supervisor_membership.can_perform_role?(:editor)
      @supervisor_membership.roles << Role.find(:supervisor)
      assert @supervisor_membership.can_perform_role?(:editor)
    end
  end

  class Role::AbilityGeneratorTest < ActiveSupport::TestCase
    def setup
      @admin_user = FactoryBot.create :onboarded_user
      @membership = FactoryBot.create :membership, user: @admin_user, team: @admin_user.current_team, role_ids: [Role.admin.id]
      @admin_ability = Ability.new(@admin_user)
      @admin_role = Role.admin
      @ability_generator = Role::AbilityGenerator.new(@admin_role, "Team", @admin_user, :memberships, :team)
    end

    test "The ability generator is valid?" do
      assert @ability_generator.valid?
    end

    test "if the model does not respond to the parent model, it should not be valid" do
      ability_generator = Role::AbilityGenerator.new(@admin_role, "Team", @admin_user, :memberships, :tangible_thing)

      refute ability_generator.valid?
    end

    test "it outputs the correct model" do
      assert_equal @ability_generator.model, Team
    end

    test "it outputs the correct actions when given a string" do
      assert_equal @ability_generator.actions, [:manage]
    end

    test "It outputs the correct actions when passed in crud" do
      ability_generator = Role::AbilityGenerator.new(Role.find_by_key("crud_role"), "Team", @admin_user, :memberships, :team)
      expected_output = %i[create read update destroy]
      assert_empty expected_output - ability_generator.actions
    end

    test "it outputs the correct actions when given an array" do
      # Find a role with an array for the permissions
      role = nil
      model = nil
      expected_output = nil

      Role.all.each do |role_test|
        role_test.models.each do |model_test, model_data|
          if model_data.is_a?(Array)
            model = model_test
            role = role_test
            expected_output = model_data
            break
          end
        end
      end

      skip "You have no abilities with array conditions defined for a model.  Skipping this test." unless role && model

      ability_generator = Role::AbilityGenerator.new(role, model, @admin_user, :memberships, :team)

      assert_empty expected_output - ability_generator.actions
    end

    test "it outputs the correct condition hash for a child object" do
      ability_generator = Role::AbilityGenerator.new(@admin_role, "Membership", @admin_user, :memberships, :team)

      assert_equal ({team_id: [@admin_user.teams.first.id]}), ability_generator.condition
    end

    test "If an object responds to team_id but it is not a database column for that object, create the permissing through the team association" do
      ability_generator = Role::AbilityGenerator.new(@admin_role, "Document", @admin_user, :memberships, :team)
      # Note: our original technique of using method_defined? breaks in ActiveRecord 7 because AR7 adds a team_id method by
      # default when you add
      # has_one :team, through: :membership
      # The gem has been updated to use the column_names attribute instead
      assert_equal ({team: {id: [@admin_user.teams.first.id]}}), ability_generator.condition
    end

    test "when the parent and the model are the same class, the condition hash checks the id attribute directly" do
      ability_generator = Role::AbilityGenerator.new(@admin_role, "Team", @admin_user, :memberships, :team)

      assert_equal ({id: [@admin_user.teams.first.id]}), ability_generator.condition
    end

    test "possible_parent_associations returns all namespace possibilities" do
      expected_output = %i[creative_concept absolutely_abstract_creative_concept scaffolding_absolutely_abstract_creative_concept]

      ability_generator = Role::AbilityGenerator.new(@admin_role, "Scaffolding::AbsolutelyAbstract::CreativeConcept", @admin_user, :scaffolding_absolutely_abstract_creative_concepts_collaborators, :creative_concept)

      assert_empty expected_output - ability_generator.possible_parent_associations
    end
  end
end
