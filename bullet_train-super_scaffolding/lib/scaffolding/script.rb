# TODO these methods were removed from the global scope in super scaffolding and moved to `Scaffolding::Transformer`,
# but oauth provider scaffolding hasn't been updated yet.

require "scaffolding"
require "scaffolding/transformer"
require "scaffolding/block_manipulator"
require "scaffolding/class_names_transformer"
require "scaffolding/oauth_providers"
require "scaffolding/routes_file_manipulator"

require_relative "../bullet_train/terminal_commands"

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

def check_required_options_for_attributes(scaffolding_type, attributes, child, parent = nil)
  attributes.each do |attribute|
    parts = attribute.split(":")
    name = parts.shift
    type = parts.join(":")

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

    if name.match?(/_id$/) || name.match?(/_ids$/)
      attribute_options ||= {}
      unless attribute_options[:vanilla]
        name_without_id = if name.match?(/_id$/)
          name.gsub(/_id$/, "")
        elsif name.match?(/_ids$/)
          name.gsub(/_ids$/, "")
        end

        attribute_options[:class_name] ||= name_without_id.classify

        file_name = "app/models/#{attribute_options[:class_name].underscore}.rb"
        unless File.exist?(file_name)
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
    field_partials = {
      boolean: "boolean",
      buttons: "string",
      cloudinary_image: "string",
      color_picker: "string",
      date_and_time_field: "datetime",
      date_field: "date_field",
      email_field: "string",
      emoji_field: "string",
      file_field: "attachment",
      options: "string",
      password_field: "string",
      phone_field: "string",
      super_select: "string",
      text_area: "text",
      text_field: "string",
      number_field: "integer",
      trix_editor: "text"
    }

    max_name_length = 0
    field_partials.each do |key, value|
      if key.to_s.length > max_name_length
        max_name_length = key.to_s.length
      end
    end

    printf "\t%#{max_name_length}s:Data Type\n".bold, "Field Partial Name"
    field_partials.each { |key, value| printf "\t%#{max_name_length}s:#{value}\n", key }

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
