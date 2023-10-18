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
  super_select: "string",
  text_area: "text",
  text_field: "string",
  number_field: "integer",
  trix_editor: "text"
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

def standard_protip
  puts "🏆 Protip: Commit your other changes before running Super Scaffolding so it's easy to undo if you (or we) make any mistakes."
  puts "If you do that, you can reset to your last commit state by using `git checkout .` and `git clean -d -f` ."
end

def git_status
  `git status`.split("\n")
end

def has_untracked_files?(status_lines)
  status_lines.include?("Untracked files:")
end

# All untracked files begin with a tab (i.e. - "\tapp/models/model.rb").
def get_untracked_files(status_lines)
  `git ls-files --other --exclude-standard`.split("\n")
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

    data_type = if type == "image" && cloudinary_enabled?
      "string"
    elsif attribute_options[:multiple]
      case type
      when "file"
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
          name.gsub(/_id$/, "")
        elsif name.match?(/_ids$/)
          name.gsub(/_ids$/, "")
        end

        attribute_options[:class_name] ||= name_without_id.classify

        file_name = Dir.glob("app/models/**/*.rb").find { |model| model.match?(/#{attribute_options[:class_name].underscore}\.rb/) } || ""

        # If a model is namespaced, the parent's model file might exist under
        # `app/models/`, but sometimes these files are modules that resolve
        # table names by providing a prefix as opposed to an actual ApplicationRecord.
        # This check ensures that the _id attribute really is a model.
        is_active_record_class = attribute_options[:class_name].constantize.ancestors.include?(ActiveRecord::Base)
        unless File.exist?(file_name) && is_active_record_class
          puts ""
          puts "Attributes that end with `_id` or `_ids` trigger awesome, powerful magic in Super Scaffolding. However, because no `#{attribute_options[:class_name]}` class was found defined in `#{file_name}`, you'll need to specify a `class_name` that exists to let us know what model class is on the other side of the association, like so:".red
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
    # "join-model" is not here because the `rails g` command is written inline in its own scaffolder.
    when "crud"
      puts "Generating #{child} model with '#{generation_command}'".green
    when "crud-field"
      generation_command = "bin/rails generate migration add_#{attributes_to_generate.join("_and_")}_to_#{child.tableize.tr("/", "_")}#{generation_command}"
      puts "Adding new fields to #{child} with '#{generation_command}'".green
    end
    puts ""

    unless @options["skip-migration-generation"]
      untracked_files = has_untracked_files?(git_status) ? get_untracked_files(git_status) : []
      generation_thread = Thread.new { `#{generation_command}` }
      generation_thread.join # Wait for the process to finish.

      newly_untracked_files = has_untracked_files?(git_status) ? get_untracked_files(git_status) : []
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

def show_usage
  puts ""
  puts "🚅  usage: bin/super-scaffold [type] (... | --help | --field-partials)"
  puts ""
  puts "Supported types of scaffolding:"
  puts ""
  BulletTrain::SuperScaffolding.scaffolders.each do |key, _|
    puts "  #{key}"
  end
  puts ""
  puts "Try `bin/super-scaffold [type]` for usage examples.".blue
  puts ""
end

# grab the _type_ of scaffold we're doing.
scaffolding_type = argv.shift

if BulletTrain::SuperScaffolding.scaffolders.include?(scaffolding_type)
  scaffolder = BulletTrain::SuperScaffolding.scaffolders[scaffolding_type].constantize
  scaffolder.new(argv, @options).run
elsif argv.count > 1
  puts ""
  puts "👋"
  puts "The command line options for Super Scaffolding have changed slightly:".yellow
  puts "To use the original Super Scaffolding that you know and love, use the `crud` option.".yellow

  show_usage
elsif ARGV.first.present?
  case ARGV.first
  when "--field-partials"
    puts "Bullet Train uses the following field partials for Super Scaffolding".blue
    puts ""

    max_name_length = 0
    FIELD_PARTIALS.each do |key, value|
      if key.to_s.length > max_name_length
        max_name_length = key.to_s.length
      end
    end

    printf "\t%#{max_name_length}s:Data Type\n".bold, "Field Partial Name"
    FIELD_PARTIALS.each { |key, value| printf "\t%#{max_name_length}s:#{value}\n", key }

    puts ""
    puts "For more details, check out the documentation:"
    puts "https://bullettrain.co/docs/field-partials"
  when "--help"
    show_usage
  else
    puts "Invalid scaffolding type \"#{ARGV.first}\".".red
    show_usage
  end
end
