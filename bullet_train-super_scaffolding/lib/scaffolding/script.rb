require "scaffolding"
require "scaffolding/transformer"
require "scaffolding/block_manipulator"
require "scaffolding/class_names_transformer"
require "scaffolding/oauth_providers"
require "scaffolding/routes_file_manipulator"

require_relative "../bullet_train/terminal_commands"

FIELD_PARTIALS = {
  address_field: nil,
  boolean: "boolean",
  buttons: "string",
  checkbox: "boolean",
  cloudinary_image: "string",
  color_picker: "string",
  date_and_time_field: "datetime",
  date_field: "date",
  email_field: "string",
  emoji_field: "string",
  file_field: "attachment",
  image: "attachment",
  options: "string",
  password_field: "string",
  phone_field: "string",
  slug: "string",
  super_select: "string",
  text_area: "text",
  text_field: "string",
  number_field: "integer",
  trix_editor: "text",
  code_editor: "text"
}

# filter out options.
argv = []
@options = {}
ARGV.each do |arg|
  if arg[0..1] == "--"
    arg = arg[2..]
    if arg.split("=").count > 1
      @options[arg.split("=")[0]] = arg.split("=")[1]
    else
      @options[arg] = true
    end
  else
    argv << arg
  end
end

def get_untracked_files
  `git ls-files --other --exclude-standard`.split("\n")
end

# class_name is a potentially namespaced class like
# "Tasks::Widget" or "Task::Widget". Here we ensure that
# the namespace doesn't clobber an existing model. If it does
# we suggest that the namespace could be pluralized.
def check_class_name_for_namespace_conflict(class_name)
  if class_name.include?("::")
    parts = class_name.split("::") # ["Task", "Widget"]
    # We drop the last segment because that's tne new model we're trying to create
    parts.pop # ["Task"]
    possible_conflicted_class_name = ""
    parts.each do |part|
      possible_conflicted_class_name += "::#{part}"
      begin
        klass = possible_conflicted_class_name.constantize
        is_active_record_class = klass&.ancestors&.include?(ActiveRecord::Base)
        is_aactive_hash_class = klass&.ancestors&.include?(ActiveHash::Base)
        if klass && (is_active_record_class || is_aactive_hash_class)
          problematic_namespace = possible_conflicted_class_name[2..]
          puts "It looks like the namespace you gave for this model conflicts with an existing class: #{klass.name}".red
          puts "You should use a namespace that doesn't clobber an existing class.".red
          puts ""
          puts "We reccomend using the pluralized version of the existing class.".red
          puts ""
          puts "For instance instead of #{problematic_namespace} use #{problematic_namespace.pluralize}".red
          exit
        end
      rescue NameError
        # this is good actually, it means we don't already have a class that will be clobbered
      end
    end
  end
end

def check_required_options_for_attributes(scaffolding_type, attributes, child, parent = nil)
  tableized_parent = nil

  # Ensure the parent attribute name has the proper namespacing for adding as a foreign key.
  if parent.present?
    if child.include?("::") && parent.include?("::")
      child_parts = child.split("::")
      parent_parts = parent.split("::")
      child_parts_dup = child_parts.dup
      parent_parts_dup = parent_parts.dup

      # Pop off however many spaces match.
      child_parts_dup.each.with_index do |child_part, idx|
        if child_part == parent_parts_dup[idx]
          child_parts.shift
          parent_parts.shift
        else
          tableized_parent = parent_parts.map(&:downcase).join("_")
          break
        end
      end
    end
    # In case we're not working with namespaces, just tableize the parent as is.
    tableized_parent ||= parent.tableize.singularize.tr("/", "_") if parent.present?
  end

  generation_command = case scaffolding_type
  when "crud"
    "bin/rails generate model #{child} #{tableized_parent}:references"
  when "crud-field"
    "" # This is blank so we can create the proper migration name first after we get the attributes.
  end

  # Even if there are attributes passed to the scaffolder,
  # They may already exist in previous migrations, so we
  # only register ones that need to be generated.
  # i.e. - *_ids attributes in the join-model scaffolder.
  attributes_to_generate = []

  attributes.each do |attribute|
    parts = attribute.split(":")
    name = parts.shift
    type = parts.join(":")
    type_without_option = type.gsub(/{.*}/, "")

    unless Scaffolding.valid_attribute_type?(type)
      raise "You have entered an invalid attribute type: #{type}. General data types are used when creating new models, but Bullet Train " \
        "uses field partials when Super Scaffolding, i.e. - `name:text_field` as opposed to `name:string`. " \
        "Please refer to the Field Partial documentation to view which attribute types are available."
    end

    # extract any options they passed in with the field.
    type, attribute_options = type.scan(/^(.*){(.*)}/).first || type

    # create a hash of the options.
    attribute_options = if attribute_options
      attribute_options.split(",").map do |s|
        option_name, option_value = s.split("=")
        [option_name.to_sym, option_value || true]
      end.to_h
    else
      {}
    end

    if type == "image" && cloudinary_enabled? && attribute_options[:multiple]
      puts "You have Cloudinary enabled and tried to scaffold an image field with the `multiple` option. " \
        "At this time we do not support multiple images in a single Cloudinary image attribute. " \
        "We hope to add support for it in the future. " \
        "For now you could use individual named image attributes, or you might try disabling Cloudinary and using ActiveStorage.".red
      exit
    end

    data_type = if type == "image" && cloudinary_enabled?
      "string"
    elsif attribute_options[:multiple]
      case type
      when "file_field"
        "attachments"
      when "image"
        "attachments"
      else
        "jsonb"
      end
    else
      FIELD_PARTIALS[type_without_option.to_sym]
    end

    if name.match?(/_id$/) || name.match?(/_ids$/)
      attribute_options ||= {}
      unless attribute_options[:vanilla]
        name_without_id = if name.match?(/_id$/)
          name.delete_suffix("_id")
        elsif name.match?(/_ids$/)
          name.delete_suffix("_ids")
        end

        attribute_options[:class_name] ||= name_without_id.classify

        file_name = Dir.glob("app/models/**/*.rb").find { |model| model.match?(/#{attribute_options[:class_name].underscore}\.rb/) } || ""

        begin
          class_name_constant = attribute_options[:class_name].constantize
        rescue NameError
          if attribute_options[:class_name] == child
            puts ""
            puts "You appear to be tryingo scaffold a model that references itself. Unfotunately this needs to be a two-step process.".red
            puts "First you should generate the model without the reference, and then add the reference as a new field. For instance:".red
            puts ""
            puts "  rails generate super_scaffold #{child}#{" " + parent if parent.present?}".red
            puts "  rails generate super_scaffold:field #{child} #{name}:#{type}".red
            puts ""
            puts "If `#{name}` is just a regular field and isn't backed by an ActiveRecord association, you can skip all this with the `{vanilla}` option, e.g.:".red
            puts ""
            puts "  rails generate super_scaffold #{child}#{" " + parent if parent.present?} #{name}:#{type}{vanilla}".red
            puts ""
            exit
          else
            # We don't do anything special here because we'll end up triggering the error message below. A self-referential model
            # is kind of a special case that's worth calling out specifically. If we just can't find the model the messaging below
            # should be sufficient to get folks on the right track.
          end
        end

        # If a model is namespaced, the parent's model file might exist under
        # `app/models/`, but sometimes these files are modules that resolve
        # table names by providing a prefix as opposed to an actual ApplicationRecord.
        # This check ensures that the _id attribute really is a model.
        is_active_record_class = class_name_constant&.ancestors&.include?(ActiveRecord::Base)
        unless File.exist?(file_name) && is_active_record_class
          puts ""
          puts "Attributes that end with `_id` or `_ids` trigger awesome, powerful magic in Super Scaffolding. However, because no `#{attribute_options[:class_name]}` class was found defined in your app, you'll need to specify a `class_name` that exists to let us know what model class is on the other side of the association, like so:".red
          puts ""
          puts "  bin/super-scaffold #{scaffolding_type} #{child}#{" " + parent if parent.present?} #{name}:#{type}{class_name=#{name.gsub(/_ids?$/, "").classify}}".red
          puts ""
          puts "If `#{name}` is just a regular field and isn't backed by an ActiveRecord association, you can skip all this with the `{vanilla}` option, e.g.:".red
          puts ""
          puts "  bin/super-scaffold #{scaffolding_type} #{child}#{" " + parent if parent.present?} #{name}:#{type}{vanilla}".red
          puts ""
          exit
        end
      end
    end

    # TODO: Is there ever a case that we want this to be a string?
    data_type = "references" if name.match?(/_id$/)

    # For join models, we don't want to generate a migration when
    # running the crud-field scaffolder in the last step, so we skip *_ids.
    # Addresses belong_to :addressable, so they don't have to be represented in a migration.
    unless name.match?(/_ids$/) || data_type.nil?
      generation_command += " #{name_without_id || name}:#{data_type}"
      attributes_to_generate << name
    end
  end

  # Generate the models/migrations with the attributes passed.
  if attributes_to_generate.any?
    case scaffolding_type
    # "join-model" and "oauth-provider" are not here because the
    # `rails g` command is written inline in their own respective scaffolders.
    when "crud"
      puts "Generating #{child} model with '#{generation_command}'".green
    when "crud-field"
      generation_command = "bin/rails generate migration add_#{attributes_to_generate.join("_and_")}_to_#{child.tableize.tr("/", "_")}#{generation_command}"
      puts "Adding new fields to #{child} with '#{generation_command}'".green
    end
    puts ""

    unless @options["skip-migration-generation"]
      untracked_files = get_untracked_files
      generation_thread = Thread.new { `#{generation_command}` }
      generation_thread.join # Wait for the process to finish.

      newly_untracked_files = get_untracked_files
      if (newly_untracked_files - untracked_files).size.zero?
        error_message = <<~MESSAGE
          Since you have already created the #{child} model, Super Scaffolding won't allow you to re-create it.
          You can either delete the model and try Super Scaffolding again, or add the `--skip-migration-generation`
          flag to Super Scaffold the classic Bullet Train way.
        MESSAGE
        puts ""
        puts error_message.red
        exit 1
      end
    end
  end
end

# grab the _type_ of scaffold we're doing.
scaffolding_type = argv.shift

if BulletTrain::SuperScaffolding.scaffolders.include?(scaffolding_type)
  scaffolder = BulletTrain::SuperScaffolding.scaffolders[scaffolding_type].constantize
  scaffolder.new(argv, @options).run
end
