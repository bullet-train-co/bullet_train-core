# frozen_string_literal: true

require "active_record"
require "rails/generators"

module BulletTrain
  module Roles
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      def add_roles_config_file
        puts("Creating role.yml inside config/models with default roles\n")

        copy_file "roles.yml", "config/models/roles.yml"

        puts("Success 🎉🎉\n\n")
      end

      def configure_models
        json_data_type_identifier = find_json_data_type_identifier

        top_level_model = ask("Which model do you want to use as a top-level model that represents Membership? (Defaults to Membership)") || "Membership"

        generate_migration_to_add_role_ids(top_level_model, json_data_type_identifier)

        include_role_support_in_top_level_model(top_level_model)

        associated_model = ask("Which model/association of #{top_level_model} do you consider to be the Team? (Default to Team)") || "Team"

        # Asks for a model we can setup some default permissions for.
        # TODO: follow back Andrew on question about this in Slack

        add_permit_to_ability_model(top_level_model, associated_model)
        add_concern_to_user
      end

      private

      def ask(question)
        puts(question)

        answer = gets.chomp

        return if answer.blank?

        answer
      end

      def db_adapter
        allowed_adapter_types = %w[mysql mysql2 sqlite postgresql trilogy]

        adapter_name = ActiveRecord::Base.connection.adapter_name.downcase

        if allowed_adapter_types.exclude?(adapter_name)
          raise NotImplementedError, "'#{adapter_name}' is not supported!"
        end

        adapter_name
      end

      def find_json_data_type_identifier
        adapter_name = db_adapter

        case adapter_name
        when "postgresql"
          "jsonb"
        else
          "json"
        end
      end

      def add_in_file(file_location, line_to_match, content_to_add)
        update_file_content = []

        file_lines = File.readlines(file_location)

        file_lines.each do |line|
          line_pattern = line_to_match
          updated_line = line

          if line.include?(line_pattern)
            trimmed_line = line.tr("\n", "")

            updated_line = "#{trimmed_line}#{content_to_add}"
          end

          update_file_content.push(updated_line)
        end

        File.write(file_location, update_file_content.join)
      end

      def migration_file_exists?(file_name)
        file_location = Dir["db/migrate/*_#{file_name}.rb"].last

        file_location.present?
      end

      def file_already_exists(message)
        puts(message)
      end

      def generate_migration_to_add_role_ids(top_level_model, json_data_type_identifier)
        top_level_model_table_name = top_level_model.underscore.pluralize

        migration_file_name = "add_role_ids_to_#{top_level_model_table_name}"

        return file_already_exists("Migration file already exists!!\n\n") if migration_file_exists?(migration_file_name)

        puts("Generating migration to add role_ids to #{top_level_model}")

        generate "migration", "#{migration_file_name} role_ids:#{json_data_type_identifier}"

        puts("Success 🎉🎉\n\n")
      end

      def line_exists_in_file?(file_location, line_to_compare)
        file_lines = File.readlines(file_location)

        file_lines.join.include?(line_to_compare)
      end

      def line_already_exists(message)
        puts(message)
      end

      def remove_new_lines_and_spaces(line)
        line.tr("\n", "").strip
      end

      def include_role_support_in_top_level_model(model_name)
        # converts 👇
        # Membership to membership
        # Admin::Membership to admin/membership
        # TeamMember to team_member
        file_location = "app/models/#{model_name.underscore}.rb"
        line_to_match = "class #{model_name.classify} < ApplicationRecord"
        content_to_add = "\n  include Roles::Support\n"

        puts("Adding 'include Roles::Support' to #{model_name}\n\n")

        if line_exists_in_file?(file_location, content_to_add)
          message = "'#{remove_new_lines_and_spaces(content_to_add)}' already exists in #{model_name}!!\n\n"

          return line_already_exists(message)
        end

        add_in_file(file_location, line_to_match, content_to_add)

        puts("Success 🎉🎉\n\n")
      end

      def add_permit_to_ability_model(top_level_model, associated_model)
        file_location = "app/models/ability.rb"
        line_to_match = "include CanCan::Ability"
        content_to_add = "\n  include Roles::Permit\n"
        puts("Adding 'include Roles::Permit' to #{associated_model}\n\n")

        if line_exists_in_file?(file_location, content_to_add)
          message = "#{remove_new_lines_and_spaces(content_to_add)} already exists in #{associated_model}!!\n\n"
          line_already_exists(message)
        else
          add_in_file(file_location, line_to_match, content_to_add)
        end

        line_to_match = "def initialize(user)"
        content_to_add = "\n    permit user, through: :#{top_level_model.downcase.pluralize}, parent: :#{associated_model.downcase} if user.present?\n"
        puts("Adding 'permit' to #{associated_model}\n\n")

        if line_exists_in_file?(file_location, content_to_add)
          message = "#{remove_new_lines_and_spaces(content_to_add)} already exists in #{associated_model}!!\n\n"
          line_already_exists(message)
        else
          add_in_file(file_location, line_to_match, content_to_add)
        end

        puts("Success 🎉🎉\n\n")
      end

      def add_concern_to_user
        file_location = "app/models/user.rb"
        line_to_match = "class User < ApplicationRecord"
        content_to_add = "\n  include Roles::User\n"
        puts("Adding 'include Roles::User' to User\n\n")

        if line_exists_in_file?(file_location, content_to_add)
          message = "#{remove_new_lines_and_spaces(content_to_add)} already exists in User!!\n\n"
          line_already_exists(message)
        else
          add_in_file(file_location, line_to_match, content_to_add)
        end

        puts("Success 🎉🎉\n\n")
      end
    end
  end
end
