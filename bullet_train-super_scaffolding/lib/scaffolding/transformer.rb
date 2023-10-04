require "indefinite_article"
require "yaml"
require "scaffolding/file_manipulator"
require "scaffolding/class_names_transformer"
require "scaffolding/attribute"

class Scaffolding::Transformer
  attr_accessor :child, :parent, :parents, :class_names_transformer, :cli_options, :additional_steps, :namespace, :suppress_could_not_find

  def update_models_abstract_class
  end

  def created_by_reference(created_by_index_name)
  end

  def approved_by_reference(approved_by_index_name)
  end

  def permit_parents
    ["Team"]
  end

  def last_joinable_parent
    "Team"
  end

  def top_level_model?
    parent == "Team" || no_parent?
  end

  # We write an explicit method here so we know we
  # aren't handling `parent` in this situation as `nil`.
  def no_parent?
    parent == "None"
  end

  def update_action_models_abstract_class(targets_n)
  end

  def initialize(child, parents, cli_options = {})
    self.child = child
    self.parent = parents.first
    self.parents = parents
    self.namespace = cli_options["namespace"] || "account"
    self.class_names_transformer = Scaffolding::ClassNamesTransformer.new(child, parent, namespace)
    self.cli_options = cli_options
    self.additional_steps = []
  end

  RUBY_NEW_FIELDS_PROCESSING_HOOK = "# 🚅 super scaffolding will insert processing for new fields above this line."
  RUBY_NEW_ARRAYS_HOOK = "# 🚅 super scaffolding will insert new arrays above this line."
  RUBY_NEW_FIELDS_HOOK = "# 🚅 super scaffolding will insert new fields above this line."
  RUBY_ADDITIONAL_NEW_FIELDS_HOOK = "# 🚅 super scaffolding will also insert new fields above this line."
  RUBY_EVEN_MORE_NEW_FIELDS_HOOK = "# 🚅 super scaffolding will additionally insert new fields above this line."
  RUBY_NEW_API_VERSION_HOOK = "# 🚅 super scaffolding will insert new api versions above this line."
  RUBY_FILES_HOOK = "# 🚅 super scaffolding will insert file-related logic above this line."
  RUBY_FACTORY_SETUP_HOOK = "# 🚅 super scaffolding will insert factory setup in place of this line."
  ERB_NEW_FIELDS_HOOK = "<%#{RUBY_NEW_FIELDS_HOOK} %>"
  CONCERNS_HOOK = "# 🚅 add concerns above."
  ATTR_ACCESSORS_HOOK = "# 🚅 add attribute accessors above."
  BELONGS_TO_HOOK = "# 🚅 add belongs_to associations above."
  HAS_MANY_HOOK = "# 🚅 add has_many associations above."
  OAUTH_PROVIDERS_HOOK = "# 🚅 add oauth providers above."
  HAS_ONE_HOOK = "# 🚅 add has_one associations above."
  SCOPES_HOOK = "# 🚅 add scopes above."
  VALIDATIONS_HOOK = "# 🚅 add validations above."
  CALLBACKS_HOOK = "# 🚅 add callbacks above."
  DELEGATIONS_HOOK = "# 🚅 add delegations above."
  METHODS_HOOK = "# 🚅 add methods above."

  def encode_double_replacement_fix(string)
    string.chars.join("~!@BT@!~")
  end

  def decode_double_replacement_fix(string)
    string.gsub("~!@BT@!~", "")
  end

  def transform_string(string)
    full_class_name = [
      "Scaffolding::AbsolutelyAbstract::CreativeConcepts",
      "Scaffolding::CompletelyConcrete::TangibleThings",
      "ScaffoldingAbsolutelyAbstractCreativeConcepts",
      "ScaffoldingCompletelyConcreteTangibleThings",
      "Scaffolding Absolutely Abstract Creative Concepts",
      "Scaffolding Completely Concrete Tangible Things",
      "Scaffolding/Absolutely Abstract/Creative Concepts",
      "Scaffolding/Completely Concrete/Tangible Things",
      "scaffolding/absolutely_abstract/creative_concepts",
      "scaffolding/completely_concrete/tangible_things",
      "scaffolding/completely_concrete/_tangible_things",
      "scaffolding_absolutely_abstract_creative_concepts",
      "scaffolding_completely_concrete_tangible_things",
      "scaffolding-absolutely-abstract-creative-concepts",
      "scaffolding-completely-concrete-tangible-things",
      "scaffolding.completely_concrete.tangible_things"
    ]

    class_name_with_context = [
      "absolutely_abstract_creative_concepts",
      "completely_concrete_tangible_things",
      "absolutely_abstract/creative_concepts",
      "completely_concrete/tangible_things",
      "absolutely-abstract-creative-concepts",
      "completely-concrete-tangible-things"
    ]

    class_name = [
      "creative_concepts",
      "tangible_things",
      "creative-concepts",
      "tangible-things",
      "Creative Concepts",
      "Tangible Things",
      "Creative concepts",
      "Tangible things",
      "creative concepts",
      "tangible things"
    ]

    (
      full_class_name + full_class_name.map(&:singularize) +
      class_name_with_context + class_name_with_context.map(&:singularize) +
      class_name + class_name.map(&:singularize) +
      [":account", "/account/"] # Account namespace vs. others.
    ).each do |needle|
      string = string.gsub(needle, encode_double_replacement_fix(class_names_transformer.replacement_for(needle)))
    end

    {
      "/v1/" => "/#{BulletTrain::Api.current_version}/",
      "::V1::" => "::#{BulletTrain::Api.current_version}::",
      "_v1_" => "_#{BulletTrain::Api.current_version}_",
      ":v1," => ":#{BulletTrain::Api.current_version},"
    }.each do |from, to|
      string = string.gsub(from.upcase, encode_double_replacement_fix(to.upcase))
      string = string.gsub(from.downcase, encode_double_replacement_fix(to.downcase))
    end

    decode_double_replacement_fix(string)
  end

  def resolve_template_path(file)
    # Figure out the actual location of the file.
    BulletTrain::SuperScaffolding.template_paths.map do |base_path|
      base_path = Pathname.new(base_path)
      resolved_path = base_path.join(file).to_s
      File.exist?(resolved_path) ? resolved_path : nil
    end.compact.first || raise("Couldn't find the Super Scaffolding template for `#{file}` in any of the following locations:\n\n#{BulletTrain::SuperScaffolding.template_paths.join("\n")}")
  end

  def resolve_target_path(file)
    # Only do something here if they are trying to specify a target directory.
    return file unless ENV["TARGET"]

    # If the file exists in the application repository, we want to target it there.
    return file if File.exist?(file)

    ENV["OTHER_TARGETS"]&.split(",")&.each do |possible_target|
      candidate_path = "#{possible_target}/#{file}".gsub("//", "/")
      return candidate_path if File.exist?(candidate_path)
    end

    "#{ENV["TARGET"]}/#{file}".gsub("//", "/")
  end

  def get_transformed_file_content(file)
    transformed_file_content = []

    skipping = false
    gathering_lines_to_repeat = false

    parents_to_repeat_for = []
    gathered_lines_for_repeating = nil

    File.open(resolve_template_path(file)).each_line do |line|
      if line.include?("# 🚅 skip when scaffolding.")
        next
      end

      if line.include?("# 🚅 skip this section if resource is nested directly under team.")
        skipping = true if parent == "Team"
        next
      end

      if line.include?("# 🚅 skip this section when scaffolding.")
        skipping = true
        next
      end

      if line.include?("# 🚅 stop any skipping we're doing now.")
        skipping = false
        next
      end

      if line.include?("# 🚅 for each child resource from team down to the resource we're scaffolding, repeat the following:")
        gathering_lines_to_repeat = true
        parents_to_repeat_for = ([child] + parents.dup).reverse
        gathered_lines_for_repeating = []
        next
      end

      if line.include?("# 🚅 stop repeating.")
        gathering_lines_to_repeat = false

        while parents_to_repeat_for.count > 1
          current_parent = parents_to_repeat_for[0]
          current_child = parents_to_repeat_for[1]
          current_transformer = self.class.new(current_child, current_parent)
          transformed_file_content << current_transformer.transform_string(gathered_lines_for_repeating.join)
          parents_to_repeat_for.shift
        end

        next
      end

      if gathering_lines_to_repeat
        gathered_lines_for_repeating << line
        next
      end

      if skipping
        next
      end

      # remove lines with 'remove in scaffolded files.'
      unless line.include?("remove in scaffolded files.")

        # only transform it if it doesn't have the lock emoji.
        if line.include?("🔒")
          # remove any comments that start with a lock.
          line.gsub!(/\s+?#\s+🔒.*/, "")
        else
          line = transform_string(line)
        end

        transformed_file_content << line

      end
    end

    transformed_file_content.join
  end

  def scaffold_file(file, overrides: false)
    transformed_file_content = get_transformed_file_content(file)
    transformed_file_name = resolve_target_path(transform_string(file))

    # Remove `_overrides` from the file name if we're sourcing from a local override folder.
    transformed_file_name.gsub!("_overrides", "") if overrides

    transformed_directory_name = File.dirname(transformed_file_name)
    unless File.directory?(transformed_directory_name)
      FileUtils.mkdir_p(transformed_directory_name)
    end

    puts "Writing '#{transformed_file_name}'." unless silence_logs?

    File.write(transformed_file_name, transformed_file_content.strip + "\n")

    if transformed_file_name.split(".").last == "rb"
      puts "Fixing Standard Ruby on '#{transformed_file_name}'." unless silence_logs?
      # `standardrb --fix #{transformed_file_name} 2> /dev/null`
    end
  end

  def scaffold_directory(directory)
    transformed_directory_name = transform_string(directory)
    begin
      Dir.mkdir(transformed_directory_name)
    rescue Errno::EEXIST => _
      puts "The directory #{transformed_directory_name} already exists, skipping generation.".yellow
    rescue Errno::ENOENT => _
      puts "Proceeding to generate '#{transformed_directory_name}'."
    end

    Dir.foreach(resolve_template_path(directory)) do |file|
      file = "#{directory}/#{file}"

      next if file.match?("/_menu_item.html.erb") && !top_level_model?

      unless File.directory?(resolve_template_path(file))
        scaffold_file(file)
      end
    end

    # Allow local developers to override just certain files of a directory.
    override_path = begin
      resolve_template_path(directory + "_overrides")
    rescue RuntimeError
      nil
    end

    if override_path
      Dir.foreach(override_path) do |file|
        file = "#{directory}_overrides/#{file}"

        next if file.match?("/_menu_item.html.erb") && !top_level_model?

        unless File.directory?(resolve_template_path(file))
          scaffold_file(file, overrides: true)
        end
      end
    end
  end

  def add_line_to_file(file, content, hook, options = {})
    increase_indent = options[:increase_indent]
    add_before = options[:add_before]
    add_after = options[:add_after]

    transformed_file_name = file
    transformed_content = content
    transform_hook = hook

    begin
      target_file_content = File.read(transformed_file_name)
    rescue Errno::ENOENT => _
      puts "Couldn't find '#{transformed_file_name}'".red unless suppress_could_not_find || options[:suppress_could_not_find]
      return false
    end

    # When Super Scaffolding strong parameters, if an attribute named :project exists for a model `Project`,
    # the `account_load_and_authorize_resource :project,` code prevents the attribute from being scaffolded
    # since the transformed content is `:project,`. We bypass that here with this check.
    content_matches_model_name = transformed_content.gsub(/[:|,]/, "").capitalize == child

    if target_file_content.include?(transformed_content) && !content_matches_model_name
      puts "No need to update '#{transformed_file_name}'. It already has '#{transformed_content}'." unless silence_logs?

    else

      new_target_file_content = []

      target_file_content.split("\n").each do |line|
        if options[:exact_match] ? line == transform_hook : line.match(/#{Regexp.escape(transform_hook)}\s*$/)

          if add_before
            new_target_file_content << "#{line} #{add_before}"
          else
            unless options[:prepend]
              new_target_file_content << line
            end
          end

          line =~ /^(\s*).*#{Regexp.escape(transform_hook)}.*/
          leading_whitespace = $1

          incoming_leading_whitespace = nil
          transformed_content.lines.each do |content_line|
            content_line.rstrip
            content_line =~ /^(\s*).*/
            # this ignores empty lines.
            # it accepts any amount of whitespace if we haven't seen any whitespace yet.
            if content_line.present? && $1 && (incoming_leading_whitespace.nil? || $1.length < incoming_leading_whitespace.length)
              incoming_leading_whitespace = $1
            end
          end

          incoming_leading_whitespace ||= ""

          transformed_content.lines.each do |content_line|
            new_target_file_content << "#{leading_whitespace}#{"  " if increase_indent}#{content_line.gsub(/^#{incoming_leading_whitespace}/, "").rstrip}".presence
          end

          new_target_file_content << "#{leading_whitespace}#{add_after}" if add_after

          if options[:prepend]
            new_target_file_content << line
          end

        else

          new_target_file_content << line

        end
      end

      puts "Updating '#{transformed_file_name}'." unless silence_logs?

      File.write(transformed_file_name, new_target_file_content.join("\n").strip + "\n")

    end
  end

  def scaffold_add_line_to_file(file, content, hook, options = {})
    file = resolve_target_path(transform_string(file))
    content = transform_string(content)
    hook = transform_string(hook)
    add_line_to_file(file, content, hook, options)
  end

  def scaffold_replace_line_in_file(file, content, content_to_replace)
    file = resolve_target_path(transform_string(file))
    # we specifically don't transform the content, we assume a builder function created this content.
    transformed_content_to_replace = transform_string(content_to_replace)
    content_replacement_transformed = content_to_replace != transformed_content_to_replace
    options = {suppress_could_not_find: suppress_could_not_find, content_replacement_transformed: content_replacement_transformed}
    Scaffolding::FileManipulator.replace_line_in_file(file, content, transformed_content_to_replace, **options)
  end

  # if class_name isn't specified, we use `child`.
  # if class_name is specified, then `child` is assumed to be a parent of `class_name`.
  # returns an array with the ability line and a boolean indicating whether the ability line should be inserted among
  # the abilities for admins only. (this happens when building an ability line for a resources that doesn't ultimately
  # belong to a Team or a User.)
  def build_ability_line(class_names = nil)
    # e.g. ['Conversations::Message', 'Conversation']
    if class_names
      # e.g. 'Conversations::Message'
      class_name = class_names.shift
      # e.g. ['Conversation', 'Deliverable', 'Phase', 'Project', 'Team']
      working_parents = class_names + [child] + parents
    else
      # e.g. 'Deliverable'
      class_name = child
      # e.g. ['Phase', 'Project', 'Team']
      working_parents = parents.dup
    end

    case working_parents.last
    when "User"
      working_parents.pop
      ability_line = "user_id: user.id"
    when "Team"
      working_parents.pop
      ability_line = "team_id: user.team_ids"
    else
      # if a resources is specified that isn't ultimately owned by a team or a user, then only admins can manage it.
      return ["can :manage, #{class_name}", true]
    end

    # e.g. ['Phase', 'Project']
    while working_parents.any?
      current_parent = working_parents.pop
      current_transformer = Scaffolding::ClassNamesTransformer.new(working_parents.last || class_name, current_parent, namespace)
      ability_line = "#{current_transformer.parent_variable_name_in_context}: {#{ability_line}}"
    end

    # e.g. "can :manage, Deliverable, phase: {project: {team_id: user.team_ids}}"
    ["can :manage, #{class_name}, #{ability_line}", false]
  end

  def build_conversation_ability_line
    build_ability_line(["Conversations::Message", "Conversation"])
  end

  def add_scaffolding_hooks_to_model
    before_scaffolding_hooks = <<~RUBY
      #{CONCERNS_HOOK}

      #{ATTR_ACCESSORS_HOOK}

    RUBY

    after_scaffolding_hooks = <<-RUBY
      #{BELONGS_TO_HOOK}

      #{HAS_MANY_HOOK}

      #{HAS_ONE_HOOK}

      #{SCOPES_HOOK}

      #{VALIDATIONS_HOOK}

      #{CALLBACKS_HOOK}

      #{DELEGATIONS_HOOK}

      #{METHODS_HOOK}
    RUBY

    # add scaffolding hooks to the model.
    unless File.readlines(transform_string("./app/models/scaffolding/completely_concrete/tangible_thing.rb")).join.include?(CONCERNS_HOOK)
      scaffold_add_line_to_file("./app/models/scaffolding/completely_concrete/tangible_thing.rb", before_scaffolding_hooks, "ApplicationRecord", increase_indent: true)
    end

    unless File.readlines(transform_string("./app/models/scaffolding/completely_concrete/tangible_thing.rb")).join.include?(BELONGS_TO_HOOK)
      scaffold_add_line_to_file("./app/models/scaffolding/completely_concrete/tangible_thing.rb", after_scaffolding_hooks, "end", prepend: true, increase_indent: true, exact_match: true)
    end
  end

  def add_ability_line_to_roles_yml(class_names = nil)
    model_names = class_names || [child]
    role_file = "./config/models/roles.yml"
    roles_hash = YAML.load_file(role_file)
    default_role_placements = [
      [:default, :models],
      [:admin, :models]
    ]

    model_names.each do |model_name|
      default_role_placements.each do |role_placement|
        stringified_role_placement = role_placement.map { |placement| placement.to_s }
        if roles_hash.dig(*stringified_role_placement)[model_name].nil?
          role_type = (role_placement.first == :admin) ? "manage" : "read"
          Scaffolding::FileManipulator.add_line_to_yml_file(role_file, "#{model_name}: #{role_type}", role_placement)
        end
      end
    end
  end

  def build_factory_setup
    class_name = child
    working_parents = parents.dup
    current_parent = working_parents.pop
    current_transformer = Scaffolding::Transformer.new(working_parents.last || class_name, [current_parent])

    setup_lines = []

    unless current_parent == "Team" || current_parent == "User"
      setup_lines << current_transformer.transform_string("@absolutely_abstract_creative_concept = create(:scaffolding_absolutely_abstract_creative_concept)")
    end

    previous_assignment = current_transformer.transform_string("absolutely_abstract_creative_concept: @absolutely_abstract_creative_concept")

    current_parent = working_parents.pop

    while current_parent
      current_transformer = Scaffolding::Transformer.new(working_parents.last || class_name, [current_parent])
      setup_lines << current_transformer.transform_string("@absolutely_abstract_creative_concept = create(:scaffolding_absolutely_abstract_creative_concept, #{previous_assignment})")
      previous_assignment = current_transformer.transform_string("absolutely_abstract_creative_concept: @absolutely_abstract_creative_concept")

      current_parent = working_parents.pop
    end

    setup_lines << current_transformer.transform_string("@tangible_thing = build(:scaffolding_completely_concrete_tangible_thing, #{previous_assignment})")

    setup_lines
  end

  def replace_in_file(file, before, after, target_regexp = nil)
    puts "Replacing in '#{file}'." unless silence_logs?
    if target_regexp.present?
      target_file_content = ""
      File.open(file).each_line do |l|
        l.gsub!(before, after) if !!l.match(target_regexp)
        target_file_content += l
      end
    else
      target_file_content = File.read(file)
      target_file_content.gsub!(before, after)
    end
    File.write(file, target_file_content)
  end

  def restart_server
    # restart the server.
    puts "Restarting the server so it picks up the new localization .yml file."
    `./bin/rails restart`
  end

  def add_locale_helper_export_fix
    namespaced_locale_export_hook = "# 🚅 super scaffolding will insert the export for the locale view helper here."

    spacer = "  "
    indentation = spacer * 3
    namespace_elements = child.underscore.pluralize.split("/")
    last_element = namespace_elements.shift
    lines_to_add = [last_element + ":"]
    namespace_elements.map do |namespace_element|
      lines_to_add << indentation + namespace_element + ":"
      last_element = namespace_element
      indentation += spacer
    end
    lines_to_add << lines_to_add.pop + " *#{last_element}"

    scaffold_replace_line_in_file("./config/locales/en/scaffolding/completely_concrete/tangible_things.en.yml", lines_to_add.join("\n"), namespaced_locale_export_hook)
  end

  def scaffold_new_breadcrumbs(child, parents)
    scaffold_file("./app/views/account/scaffolding/completely_concrete/tangible_things/_breadcrumbs.html.erb")
    puts
    puts "Heads up! We're only able to generate the new breadcrumb views, so you'll have to edit `#{transform_string("./config/locales/en/scaffolding/completely_concrete/tangible_things.en.yml")}` and add the label. You can look at `./config/locales/en/scaffolding/completely_concrete/tangible_things.en.yml` for an example of how to do this, but here's an example of what it should look like:".yellow
    puts
    puts transform_string("en:\n  scaffolding/completely_concrete/tangible_things: &tangible_things\n    label: &label Things\n    breadcrumbs:\n      label: *label").yellow
    puts
  end

  def add_has_many_association
    has_many_line = ["has_many :completely_concrete_tangible_things"]

    # Specify the class name if the model is namespaced.
    if child.match?("::")
      has_many_line << "class_name: \"Scaffolding::CompletelyConcrete::TangibleThing\""
    end

    has_many_line << "dependent: :destroy"

    # Specify the foreign key if the parent is namespaced.
    if parent.match?("::")
      has_many_line << "foreign_key: :absolutely_abstract_creative_concept_id"

      # And if we need `foreign_key`, we should also specify `inverse_of`.
      has_many_line << "inverse_of: :absolutely_abstract_creative_concept"
    end

    has_many_string = transform_string(has_many_line.join(", "))
    add_line_to_file(transform_string("./app/models/scaffolding/absolutely_abstract/creative_concept.rb"), has_many_string, HAS_MANY_HOOK, prepend: true)

    # Return the name of the has_many association.
    has_many_string.split(",").first.split(":").last
  end

  def add_has_many_through_associations(has_many_through_transformer)
    has_many_association = add_has_many_association
    has_many_through_string = has_many_through_transformer.transform_string("has_many :completely_concrete_tangible_things, through: :$HAS_MANY_ASSOCIATION")
    has_many_through_string.gsub!("$HAS_MANY_ASSOCIATION", has_many_association)
    add_line_to_file(transform_string("./app/models/scaffolding/absolutely_abstract/creative_concept.rb"), has_many_through_string, HAS_MANY_HOOK, prepend: true)
  end

  def add_attributes_to_various_views(attributes, scaffolding_options = {})
    sql_type_to_field_type_mapping = {
      # 'binary' => '',
      "boolean" => "options",
      "date" => "date_field",
      "datetime" => "date_and_time_field",
      "decimal" => "text_field",
      "float" => "text_field",
      "integer" => "text_field",
      "bigint" => "text_field",
      # 'primary_key' => '',
      # 'references' => '',
      "string" => "text_field",
      "text" => "text_area"
      # 'time' => '',
      # 'timestamp' => '',
    }

    # add attributes to various views.
    attributes.each_with_index do |attribute_definition, index|
      attribute = Scaffolding::Attribute.new(attribute_definition, scaffolding_options[:type], index)

      if attribute.is_first_attribute? && ["trix_editor", "ckeditor", "text_area"].include?(attribute.type)
        puts ""
        puts "The first attribute of your model cannot be any of the following types:".red
        puts "1. trix_editor"
        puts "2. ckeditor"
        puts "3. text_area"
        puts ""
        puts "Please ensure you have another attribute type as the first attribute for your model and try again."

        exit
      end

      if sql_type_to_field_type_mapping[attribute.type]
        attribute.type = sql_type_to_field_type_mapping[attribute.type]
      end

      cell_attributes = if attribute.is_boolean?
        ' class="text-center"'
      end

      # don't do table columns for certain types of fields and attribute partials
      if ["trix_editor", "ckeditor", "text_area"].include?(attribute.type) || ["html", "has_many"].include?(attribute.partial_name)
        cli_options["skip-table"] = true
      end

      if attribute.type == "none"
        cli_options["skip-form"] = true
      end

      if attribute.partial_name == "none"
        cli_options["skip-show"] = true
        cli_options["skip-table"] = true
      end

      #
      # MODEL VALIDATIONS
      #

      unless cli_options["skip-form"] || attribute.is_unscoped?

        file_name = "./app/models/scaffolding/completely_concrete/tangible_thing.rb"

        if attribute.is_association?
          field_content = if attribute.options[:source]
            <<~RUBY
              def valid_#{attribute.collection_name}
                #{attribute.options[:source]}
              end

            RUBY
          else
            add_additional_step :yellow, transform_string("You'll need to implement the `valid_#{attribute.collection_name}` method of `Scaffolding::CompletelyConcrete::TangibleThing` in `./app/models/scaffolding/completely_concrete/tangible_thing.rb`. This is the method that will be used to populate the `#{attribute.type}` field and also validate that users aren't trying to exploit multitenancy.")

            <<~RUBY
              def valid_#{attribute.collection_name}
                raise "please review and implement `valid_#{attribute.collection_name}` in `app/models/scaffolding/completely_concrete/tangible_thing.rb`."
                # please specify what objects should be considered valid for assigning to `#{attribute.name_without_id}`.
                # the resulting code should probably look something like `team.#{attribute.collection_name}`.
              end

            RUBY
          end

          scaffold_add_line_to_file(file_name, field_content, METHODS_HOOK, prepend: true)

          if attribute.is_belongs_to?
            scaffold_add_line_to_file(file_name, "validates :#{attribute.name_without_id}, scope: true", VALIDATIONS_HOOK, prepend: true)
          end

          # TODO we need to add a multitenancy check for has many associations.
        end

      end

      #
      # FORM FIELD
      #

      unless cli_options["skip-form"] || attribute.options[:readonly]

        # add `has_rich_text` for trix editor fields.
        if attribute.type == "trix_editor"
          file_name = "./app/models/scaffolding/completely_concrete/tangible_thing.rb"
          scaffold_add_line_to_file(file_name, "has_rich_text :#{attribute.name}", HAS_ONE_HOOK, prepend: true)
        end

        # field on the form.
        field_attributes = {method: ":#{attribute.name}"}
        field_options = {}
        options = {}

        if attribute.is_first_attribute?
          field_options[:autofocus] = "true"
        end

        if attribute.is_id? && attribute.type == "super_select"
          options[:include_blank] = "t('.fields.#{attribute.name}.placeholder')"
          # add_additional_step :yellow, transform_string("We've added a reference to a `placeholder` to the form for the select or super_select field, but unfortunately earlier versions of the scaffolded locales Yaml don't include a reference to `fields: *fields` under `form`. Please add it, otherwise your form won't be able to locate the appropriate placeholder label.")
        end

        if attribute.type == "color_picker"
          field_options[:color_picker_options] = "t('#{child.pluralize.underscore}.fields.#{attribute.name}.options')"
        end

        # When rendering a super_select element we need to use `html_options: {multiple: true}`,
        # but all other fields simply use `multiple: true` to work.
        if attribute.is_multiple?
          if attribute.type == "super_select"
            field_options[:multiple] = "true"
          else
            field_attributes[:multiple] = "true"
          end
        end

        valid_values = if attribute.is_id?
          "valid_#{attribute.name_without_id.pluralize}"
        elsif attribute.is_ids?
          "valid_#{attribute.collection_name}"
        end

        # https://stackoverflow.com/questions/21582464/is-there-a-ruby-hashto-s-equivalent-for-the-new-hash-syntax
        if field_options.any? || options.any?
          field_options_key = if ["buttons", "super_select", "options"].include?(attribute.type)
            if options.any?
              field_attributes[:options] = "{" + field_options.map { |key, value| "#{key}: #{value}" }.join(", ") + "}"
            end

            :html_options
          else
            field_options.merge!(options)

            :options
          end

          field_attributes[field_options_key] = "{" + field_options.map { |key, value| "#{key}: #{value}" }.join(", ") + "}"
        end

        if attribute.is_association?
          short = attribute.options[:class_name].underscore.split("/").last
          case attribute.type
          when "buttons", "options"
            field_attributes["\n  options"] = "@tangible_thing.#{valid_values}.map { |#{short}| [#{short}.id, #{short}.#{attribute.options[:label]}] }"
          when "super_select"
            field_attributes["\n  choices"] = "@tangible_thing.#{valid_values}.map { |#{short}| [#{short}.#{attribute.options[:label]}, #{short}.id] }"
          end
        end

        field_content = "<%= render 'shared/fields/#{attribute.type}'#{", " if field_attributes.any?}#{field_attributes.map { |key, value| "#{key}: #{value}" }.join(", ")} %>"

        # TODO Add more of these from other packages?
        is_core_model = ["Team", "User", "Membership"].include?(child)

        scaffold_add_line_to_file("./app/views/account/scaffolding/completely_concrete/tangible_things/_form.html.erb", field_content, ERB_NEW_FIELDS_HOOK, prepend: true, suppress_could_not_find: is_core_model)
        scaffold_add_line_to_file("./app/views/account/scaffolding/completely_concrete/tangible_things/_fields.html.erb", field_content, ERB_NEW_FIELDS_HOOK, prepend: true, suppress_could_not_find: !is_core_model)
      end

      #
      # SHOW VIEW
      #

      unless cli_options["skip-show"]

        if attribute.is_id?
          <<~ERB
            <% if @tangible_thing.#{attribute.name_without_id} %>
              <div class="form-group">
                <label class="col-form-label"><%= t('.fields.#{attribute.name}.heading') %></label>
                <div>
                  <%= link_to @tangible_thing.#{attribute.name_without_id}.#{attribute.options[:label]}, [:account, @tangible_thing.#{attribute.name_without_id}] %>
                </div>
              </div>
            <% end %>
          ERB
        elsif attribute.is_ids?
          <<~ERB
            <% if @tangible_thing.#{attribute.collection_name}.any? %>
              <div class="form-group">
                <label class="col-form-label"><%= t('.fields.#{attribute.name}.heading') %></label>
                <div>
                  <%= @tangible_thing.#{attribute.collection_name}.map { |#{attribute.name_without_ids}| link_to #{attribute.name_without_ids}.#{attribute.options[:label]}, [:account, #{attribute.name_without_ids}] }.to_sentence.html_safe %>
                </div>
              </div>
            <% end %>
          ERB
        end

        # this gets stripped and is one line, so indentation isn't a problem.
        field_content = <<-ERB
          <%= render 'shared/attributes/#{attribute.partial_name}', attribute: :#{attribute.is_vanilla? ? attribute.name : attribute.name_without_id_suffix} %>
        ERB

        if attribute.type == "password_field"
          field_content.gsub!(/\s%>/, ", options: { password: true } %>")
        end

        show_page_doesnt_exist = child == "User"
        scaffold_add_line_to_file("./app/views/account/scaffolding/completely_concrete/tangible_things/show.html.erb", field_content.strip, ERB_NEW_FIELDS_HOOK, prepend: true, suppress_could_not_find: show_page_doesnt_exist)

      end

      #
      # INDEX TABLE
      #

      unless cli_options["skip-table"]

        # table header.
        field_content = "<th#{cell_attributes.present? ? " " + cell_attributes : ""}><%= t('.fields.#{attribute.is_vanilla? ? attribute.name : attribute.name_without_id_suffix}.heading') %></th>"

        unless ["Team", "User"].include?(child)
          scaffold_add_line_to_file("./app/views/account/scaffolding/completely_concrete/tangible_things/_index.html.erb", field_content, "<%# 🚅 super scaffolding will insert new field headers above this line. %>", prepend: true)
        end

        # If these strings are the same, we get duplicate variable names in the _index.html.erb partial,
        # so we account for that here. Run the Super Scaffolding test setup script and check the index partial
        # of models with namespaced parents for reference (i.e. - Objective, Projects::Step).
        transformed_abstract_str = transform_string("absolutely_abstract_creative_concept")
        transformed_concept_str = transform_string("creative_concept")
        transformed_file_name = transform_string("./app/views/account/scaffolding/completely_concrete/tangible_things/_index.html.erb")
        if (transformed_abstract_str == transformed_concept_str) && File.exist?(transformed_file_name)
          replace_in_file(
            transformed_file_name,
            "#{transformed_abstract_str} = @#{transformed_abstract_str} || @#{transformed_concept_str}",
            "#{transformed_abstract_str} = @#{transformed_concept_str}"
          )
        end

        table_cell_options = []

        if attribute.is_first_attribute?
          table_cell_options << "url: [:account, tangible_thing]"
        end

        # this gets stripped and is one line, so indentation isn't a problem.
        field_content = <<-ERB
          <td#{cell_attributes}><%= render 'shared/attributes/#{attribute.partial_name}', attribute: :#{attribute.is_vanilla? ? attribute.name : attribute.name_without_id_suffix}#{", #{table_cell_options.join(", ")}" if table_cell_options.any?} %></td>
        ERB

        case attribute.type
        when "password_field"
          field_content.gsub!(/\s%>/, ", options: { password: true } %>")
        when "address_field"
          field_content.gsub!(/\s%>/, ", one_line: true %>")
        end

        unless ["Team", "User"].include?(child)
          scaffold_add_line_to_file("./app/views/account/scaffolding/completely_concrete/tangible_things/_tangible_thing.html.erb", field_content.strip, ERB_NEW_FIELDS_HOOK, prepend: true)
        end

      end

      #
      # LOCALIZATIONS
      #

      unless cli_options["skip-locales"]

        yaml_template = <<~YAML

          <%= attribute.name %>: <% if attribute.is_association? %>&<%= attribute.name_without_id_suffix %><% end %>
            _: &#{attribute.name} #{attribute.title_case}
            label: *#{attribute.name}
            heading: *#{attribute.name}

            <% if attribute.type == "super_select" %>
            <% if attribute.is_required? %>
            placeholder: Select <% attribute.title_case.with_indefinite_article %>
            <% else %>
            placeholder: None
            <% end %>
            <% end %>

            <% if attribute.is_boolean? %>

            options:
              yes: "Yes"
              no: "No"

            <% elsif ["buttons", "super_select", "options"].include?(attribute.type) && !attribute.is_association? %>

            options:
              one: One
              two: Two
              three: Three

            <% end %>

            <% if attribute.type == "color_picker" %>
            options:
              - '#9C73D2'
              - '#48CDFE'
              - '#53F3ED'
              - '#47E37F'
              - '#F2593D'
              - '#F68421'
              - '#F9DE00'
              - '#929292'
            <% end %>

          <% if attribute.is_association? %>
          <%= attribute.name_without_id_suffix %>: *<%= attribute.name_without_id_suffix %>
          <% end %>
        YAML

        field_content = ERB.new(yaml_template).result(binding).lines.select(&:present?).join

        scaffold_add_line_to_file("./config/locales/en/scaffolding/completely_concrete/tangible_things.en.yml", field_content, RUBY_NEW_FIELDS_HOOK, prepend: true)

        # active record's field label.
        scaffold_add_line_to_file("./config/locales/en/scaffolding/completely_concrete/tangible_things.en.yml", "#{attribute.name}: *#{attribute.name}", "# 🚅 super scaffolding will insert new activerecord attributes above this line.", prepend: true)

      end

      #
      # STRONG PARAMETERS
      #

      unless cli_options["skip-form"] || attribute.options[:readonly]

        # add attributes to strong params.
        [
          "./app/controllers/account/scaffolding/completely_concrete/tangible_things_controller.rb",
          "./app/controllers/api/v1/scaffolding/completely_concrete/tangible_things_controller.rb"
        ].each do |file|
          if attribute.is_ids? || attribute.is_multiple?
            scaffold_add_line_to_file(file, "#{attribute.name}: [],", RUBY_NEW_ARRAYS_HOOK, prepend: true)
            if attribute.type == "file_field"
              scaffold_add_line_to_file(file, "#{attribute.name}_removal: [],", RUBY_NEW_ARRAYS_HOOK, prepend: true)
            end
          elsif attribute.type == "address_field"
            address_strong_params = <<~RUBY
              #{attribute.name}_attributes: [
                :id,
                :_destroy,
                :address_one,
                :address_two,
                :city,
                :country_id,
                :region_id,
                :postal_code
              ],
            RUBY
            scaffold_add_line_to_file(file, address_strong_params, RUBY_NEW_ARRAYS_HOOK, prepend: true)
          else
            scaffold_add_line_to_file(file, ":#{attribute.name},", RUBY_NEW_FIELDS_HOOK, prepend: true)
            if attribute.type == "file_field"
              scaffold_add_line_to_file(file, ":#{attribute.name}_removal,", RUBY_NEW_FIELDS_HOOK, prepend: true)
            end
          end
        end

        scaffold_add_line_to_file("./app/controllers/account/scaffolding/completely_concrete/tangible_things_controller.rb", attribute.special_processing, RUBY_NEW_FIELDS_PROCESSING_HOOK, prepend: true) if attribute.special_processing
      end

      #
      # ASSOCIATED MODELS
      #

      unless cli_options["skip-form"] || attribute.options[:readonly]

        # set default values for associated models.
        case attribute.type
        when "address_field"
          scaffold_add_line_to_file("./app/controllers/account/scaffolding/completely_concrete/tangible_things_controller.rb", "before_action :set_default_#{attribute.name}, except: :index", "ApplicationController", increase_indent: true)

          method_content = <<~RUBY

            def set_default_#{attribute.name}
              @tangible_thing.#{attribute.name} ||= Address.new
            end
          RUBY
          scaffold_add_line_to_file("./app/controllers/account/scaffolding/completely_concrete/tangible_things_controller.rb", method_content, "end", prepend: true, increase_indent: true, exact_match: true)
        end

      end

      #
      # API SERIALIZER
      #

      unless cli_options["skip-api"]

        # TODO The serializers can't handle these `has_rich_text` attributes.
        unless attribute.type == "trix_editor"
          unless attribute.type == "file_field"
            scaffold_add_line_to_file("./app/views/api/v1/scaffolding/completely_concrete/tangible_things/_tangible_thing.json.jbuilder", ":#{attribute.name},", RUBY_NEW_FIELDS_HOOK, prepend: true, suppress_could_not_find: true)
          end

          assertion = case attribute.type
          when "date_field"
            "assert_equal_or_nil Date.parse(tangible_thing_data['#{attribute.name}']), tangible_thing.#{attribute.name}"
          when "date_and_time_field"
            "assert_equal_or_nil DateTime.parse(tangible_thing_data['#{attribute.name}']), tangible_thing.#{attribute.name}"
          when "file_field"
            if attribute.is_multiple?
              "assert_equal tangible_thing_data['#{attribute.name}'], @tangible_thing.#{attribute.name}.map{|file| rails_blob_path(file)} unless controller.action_name == 'create'"
            else
              "assert_equal tangible_thing_data['#{attribute.name}'], rails_blob_path(@tangible_thing.#{attribute.name}) unless controller.action_name == 'create'"
            end
          else
            "assert_equal_or_nil tangible_thing_data['#{attribute.name}'], tangible_thing.#{attribute.name}"
          end
          scaffold_add_line_to_file("./test/controllers/api/v1/scaffolding/completely_concrete/tangible_things_controller_test.rb", assertion, RUBY_NEW_FIELDS_HOOK, prepend: true)
        end

        # File fields are handled in a specific way when using the jsonapi-serializer.
        if attribute.type == "file_field"
          jbuilder_content = if attribute.is_multiple?
            <<~RUBY
              json.#{attribute.name} do 
                json.array! tangible_thing.#{attribute.name}.map { |file| url_for(file)  }
              end if tangible_thing.#{attribute.name}.attached?
            RUBY
          else
            "json.#{attribute.name} url_for(tangible_thing.#{attribute.name}) if tangible_thing.#{attribute.name}.attached?"
          end

          scaffold_add_line_to_file("./app/views/api/v1/scaffolding/completely_concrete/tangible_things/_tangible_thing.json.jbuilder", jbuilder_content, RUBY_FILES_HOOK, prepend: true, suppress_could_not_find: true)
          # We also want to make sure we attach the dummy file in the API test on setup
          file_name = "./test/controllers/api/v1/scaffolding/completely_concrete/tangible_things_controller_test.rb"
          content = if attribute.is_multiple?
            <<~RUBY
              @#{child.underscore}.#{attribute.name} = [Rack::Test::UploadedFile.new("test/support/foo.txt")]
              @another_#{child.underscore}.#{attribute.name} = [Rack::Test::UploadedFile.new("test/support/foo.txt")]
            RUBY
          else
            <<~RUBY
              @#{child.underscore}.#{attribute.name} = Rack::Test::UploadedFile.new("test/support/foo.txt")
              @another_#{child.underscore}.#{attribute.name} = Rack::Test::UploadedFile.new("test/support/foo.txt")
            RUBY
          end
          scaffold_add_line_to_file(file_name, content, RUBY_FILES_HOOK, prepend: true)
        end

        if attribute.default_value
          unless attribute.options[:readonly]
            scaffold_add_line_to_file("./test/controllers/api/v1/scaffolding/completely_concrete/tangible_things_controller_test.rb", "#{attribute.name}: #{attribute.default_value},", RUBY_ADDITIONAL_NEW_FIELDS_HOOK, prepend: true)
            scaffold_add_line_to_file("./test/controllers/api/v1/scaffolding/completely_concrete/tangible_things_controller_test.rb", "assert_equal @tangible_thing.#{attribute.name}, #{attribute.default_value}", RUBY_EVEN_MORE_NEW_FIELDS_HOOK, prepend: true)
          end
        end
      end

      #
      # OPENAPI DOCUMENTS
      #

      unless cli_options["skip-api"]
        # We always want to suppress this error for this file, since it doesn't exist by default. We reset this below.
        suppress_could_not_find_state = suppress_could_not_find
        self.suppress_could_not_find = true

        # It's OK that this won't be found most of the time.
        scaffold_add_line_to_file(
          "./app/views/api/v1/open_api/scaffolding/completely_concrete/tangible_things/_components.yaml.erb",
          "<%= attribute :#{attribute.name} %>",
          "<%# 🚅 super scaffolding will insert new attributes above this line. %>",
          prepend: true
        )

        # It's OK that this won't be found most of the time.
        scaffold_add_line_to_file(
          "./app/views/api/v1/open_api/scaffolding/completely_concrete/tangible_things/_components.yaml.erb",
          "<%= parameter :#{attribute.name} %>",
          "<%# 🚅 super scaffolding will insert new parameter above this line. %>",
          prepend: true
        )

        self.suppress_could_not_find = suppress_could_not_find_state
      end

      #
      # MODEL ASSOCATIONS
      #

      unless cli_options["skip-model"]

        if attribute.is_belongs_to?
          unless attribute.options[:class_name]
            attribute.options[:class_name] = attribute.name_without_id.classify
          end

          file_name = "app/models/#{attribute.options[:class_name].underscore}.rb"
          unless File.exist?(file_name)
            raise "You'll need to specify a `class_name` option for `#{attribute.name}` because there is no `#{attribute.options[:class_name].classify}` model defined in `#{file_name}`. Try again with `#{attribute.name}:#{attribute.type}[class_name=SomeClassName]`."
          end

          modified_migration = false

          # find the database migration that defines this relationship.
          expected_reference = "add_reference :#{class_names_transformer.table_name}, :#{attribute.name_without_id}"
          migration_file_name = `grep "#{expected_reference}" db/migrate/*`.split(":").first

          # if that didn't work, see if we can find a creation of the reference when the table was created.
          unless migration_file_name
            confirmation_reference = "create_table :#{class_names_transformer.table_name}"
            confirmation_migration_file_name = `grep "#{confirmation_reference}" db/migrate/*`.split(":").first

            fallback_reference = "t.references :#{attribute.name_without_id}"
            fallback_migration_file_name = `grep "#{fallback_reference}" db/migrate/* | grep #{confirmation_migration_file_name}`.split(":").first

            if fallback_migration_file_name == confirmation_migration_file_name
              migration_file_name = fallback_migration_file_name
            end
          end

          unless attribute.is_required?

            if migration_file_name
              replace_in_file(migration_file_name, ":#{attribute.name_without_id}, null: false", ":#{attribute.name_without_id}, null: true")
              modified_migration = true
            else
              add_additional_step :yellow, "We would have expected there to be a migration that defined `#{expected_reference}`, but we didn't find one. Where was the reference added to this model? It's _probably_ the original creation of the table, but we couldn't find that either. Either way, you need to rollback, change 'null: false' to 'null: true' for this column, and re-run the migration (unless, of course, that attribute _is_ required, then you need to add a validation on the model)."
            end

          end

          class_name_matches = attribute.name_without_id.tableize == attribute.options[:class_name].tableize.tr("/", "_")

          # but also, if namespaces are involved, just don't...
          if attribute.options[:class_name].include?("::")
            class_name_matches = false
          end

          # unless the table name matches the association name.
          unless class_name_matches
            if migration_file_name
              # There are two forms this association creation can take.
              replace_in_file(migration_file_name, "foreign_key: true", "foreign_key: {to_table: \"#{attribute.options[:class_name].tableize.tr("/", "_")}\"}", /t\.references :#{attribute.name_without_id}/)
              replace_in_file(migration_file_name, "foreign_key: true", "foreign_key: {to_table: \"#{attribute.options[:class_name].tableize.tr("/", "_")}\"}", /add_reference :#{child.underscore.pluralize.tr("/", "_")}, :#{attribute.name_without_id}/)

              modified_migration = true
            else
              add_additional_step :yellow, "We would have expected there to be a migration that defined `#{expected_reference}`, but we didn't find one. Where was the reference added to this model? It's _probably_ the original creation of the table. Either way, you need to rollback, change \"foreign_key: true\" to \"foreign_key: {to_table: '#{attribute.options[:class_name].tableize.tr("/", "_")}'}\" for this column, and re-run the migration."
            end
          end

          optional_line = ", optional: true" unless attribute.is_required?

          # if the `belongs_to` is already there from `rails g model`..
          scaffold_replace_line_in_file(
            "./app/models/scaffolding/completely_concrete/tangible_thing.rb",
            class_name_matches ?
              "belongs_to :#{attribute.name_without_id}#{optional_line}" :
              "belongs_to :#{attribute.name_without_id}, class_name: \"#{attribute.options[:class_name]}\"#{optional_line}",
            "belongs_to :#{attribute.name_without_id}"
          )

          # if it wasn't there, the replace will not have done anything, so we insert it entirely.
          # however, this won't do anything if the association is already there.
          scaffold_add_line_to_file(
            "./app/models/scaffolding/completely_concrete/tangible_thing.rb",
            class_name_matches ?
              "belongs_to :#{attribute.name_without_id}#{optional_line}" :
              "belongs_to :#{attribute.name_without_id}, class_name: \"#{attribute.options[:class_name]}\"#{optional_line}",
            BELONGS_TO_HOOK,
            prepend: true
          )

          if modified_migration
            add_additional_step :yellow, "If you've already run the migration in `#{migration_file_name}`, you'll need to roll back and run it again."
          end
        end

        # Add `default: false` to boolean migrations.
        if attribute.is_boolean?
          # Give priority to crud-field migrations if they exist.
          add_column_reference = "add_column :#{class_names_transformer.table_name}, :#{attribute.name}"
          create_table_reference = "create_table :#{class_names_transformer.table_name}"
          confirmation_migration_file_name = `grep "#{add_column_reference}" db/migrate/*`.split(":").first
          confirmation_migration_file_name ||= `grep "#{create_table_reference}" db/migrate/*`.split(":").first

          old_line, new_line = nil
          File.open(confirmation_migration_file_name) do |migration_file|
            old_lines = migration_file.readlines
            old_lines.each do |line|
              target_attribute = line.match?(/:#{class_names_transformer.table_name}, :#{attribute.name}, :boolean/) || line.match?(/\s*t\.boolean :#{attribute.name}/)
              if target_attribute
                old_line = line
                new_line = "#{old_line.chomp}, default: false\n"
              end
            end
          end
          replace_in_file(confirmation_migration_file_name, old_line, new_line)
        end

      end

      #
      # MODEL HOOKS
      #

      unless cli_options["skip-model"]

        if attribute.is_required? && !attribute.is_belongs_to?
          scaffold_add_line_to_file("./app/models/scaffolding/completely_concrete/tangible_thing.rb", "validates :#{attribute.name}, presence: true", VALIDATIONS_HOOK, prepend: true)
        end

        case attribute.type
        when "file_field"
          remove_file_methods = if attribute.is_multiple?
            <<~RUBY
              def #{attribute.name}_removal?
                #{attribute.name}_removal&.any?
              end

              def remove_#{attribute.name}
                #{attribute.name}_attachments.where(id: #{attribute.name}_removal).map(&:purge)
              end

              def #{attribute.name}=(attachables)
                attachables = Array(attachables).compact_blank
            
                if attachables.any?
                  attachment_changes["#{attribute.name}"] =
                    ActiveStorage::Attached::Changes::CreateMany.new("#{attribute.name}", self, #{attribute.name}.blobs + attachables)
                end
              end

            RUBY
          else
            <<~RUBY
              def #{attribute.name}_removal?
                #{attribute.name}_removal.present?
              end

              def remove_#{attribute.name}
                #{attribute.name}.purge
              end
            RUBY
          end

          # Generating a model with an `attachment(s)` data type (i.e. - `rails g ModelName file:attachment`)
          # adds `has_one_attached` or `has_many_attached` to our model, just not directly above the
          # HAS_ONE_HOOK or the HAS_MANY_HOOK. We move the string here so it's scaffolded above the proper hook.
          model_file_path = transform_string("./app/models/scaffolding/completely_concrete/tangible_thing.rb")
          model_contents = File.readlines(model_file_path)
          reflection_declaration = attribute.is_multiple? ? "has_many_attached :#{attribute.name}" : "has_one_attached :#{attribute.name}"

          # Save the file without the hook so we can write it via the `scaffold_add_line_to_file` method below.
          model_without_attached_hook = model_contents.reject.each { |line| line.include?(reflection_declaration) }
          File.open(model_file_path, "w") do |f|
            model_without_attached_hook.each { |line| f.write(line) }
          end

          hook_type = attribute.is_multiple? ? HAS_MANY_HOOK : HAS_ONE_HOOK
          scaffold_add_line_to_file("./app/models/scaffolding/completely_concrete/tangible_thing.rb", reflection_declaration, hook_type, prepend: true)

          # TODO: We may need to edit these depending on how we save multiple files.
          scaffold_add_line_to_file("./app/models/scaffolding/completely_concrete/tangible_thing.rb", "attr_accessor :#{attribute.name}_removal", ATTR_ACCESSORS_HOOK, prepend: true)
          scaffold_add_line_to_file("./app/models/scaffolding/completely_concrete/tangible_thing.rb", remove_file_methods, METHODS_HOOK, prepend: true)
          scaffold_add_line_to_file("./app/models/scaffolding/completely_concrete/tangible_thing.rb", "after_validation :remove_#{attribute.name}, if: :#{attribute.name}_removal?", CALLBACKS_HOOK, prepend: true)
        when "trix_editor"
          scaffold_add_line_to_file("./app/models/scaffolding/completely_concrete/tangible_thing.rb", "has_rich_text :#{attribute.name}", HAS_ONE_HOOK, prepend: true)
        when "address_field"
          scaffold_add_line_to_file("./app/models/scaffolding/completely_concrete/tangible_thing.rb", "has_one :#{attribute.name}, class_name: \"Address\", as: :addressable", HAS_ONE_HOOK, prepend: true)
          scaffold_add_line_to_file("./app/models/scaffolding/completely_concrete/tangible_thing.rb", "accepts_nested_attributes_for :#{attribute.name}", HAS_ONE_HOOK, prepend: true)
        when "buttons"
          if attribute.is_boolean?
            scaffold_add_line_to_file("./app/models/scaffolding/completely_concrete/tangible_thing.rb", "validates :#{attribute.name}, inclusion: [true, false]", VALIDATIONS_HOOK, prepend: true)
          end
        end

      end
    end
  end

  def add_additional_step(color, message)
    additional_steps.push [color, message]
  end

  def scaffold_crud(attributes)
    if cli_options["only-index"]
      cli_options["skip-table"] = false
      cli_options["skip-views"] = true
      cli_options["skip-controller"] = true
      cli_options["skip-form"] = true
      cli_options["skip-show"] = true
      cli_options["skip-form"] = true
      cli_options["skip-api"] = true
      cli_options["skip-model"] = true
      cli_options["skip-parent"] = true
      cli_options["skip-locales"] = true
      cli_options["skip-routes"] = true
    end

    if cli_options["namespace"]
      cli_options["skip-api"] = true
      cli_options["skip-model"] = true
      cli_options["skip-locales"] = true
    end

    # TODO fix this. we can do this better.
    files = if cli_options["only-index"]
      [
        "./app/views/account/scaffolding/completely_concrete/tangible_things/_index.html.erb",
        "./app/views/account/scaffolding/completely_concrete/tangible_things/index.html.erb",
        "./app/views/account/scaffolding/completely_concrete/tangible_things/_tangible_thing.html.erb"
      ]
    else
      # copy a ton of files over and do the appropriate string replace.
      [
        "./app/controllers/account/scaffolding/completely_concrete/tangible_things_controller.rb",
        "./app/views/account/scaffolding/completely_concrete/tangible_things",
        "./app/views/api/v1/scaffolding/completely_concrete/tangible_things",
        ("./config/locales/en/scaffolding/completely_concrete/tangible_things.en.yml" unless cli_options["skip-locales"]),
        ("./app/controllers/api/v1/scaffolding/completely_concrete/tangible_things_controller.rb" unless cli_options["skip-api"]),
        ("./test/controllers/api/v1/scaffolding/completely_concrete/tangible_things_controller_test.rb" unless cli_options["skip-api"])
        # "./app/filters/scaffolding/completely_concrete/tangible_things_filter.rb"
      ].compact
    end

    files.each do |name|
      if File.directory?(resolve_template_path(name))
        scaffold_directory(name)
      else
        scaffold_file(name)
      end
    end

    unless cli_options["skip-model"]
      # find the database migration that defines this relationship.
      migration_file_name = `grep "create_table :#{class_names_transformer.table_name}.*do |t|$" db/migrate/*`.split(":").first
      unless migration_file_name.present?
        raise "No migration file seems to exist for creating the table `#{class_names_transformer.table_name}`.\n" \
          "Please run the following command first and try Super Scaffolding again:\n" \
          "rails generate model #{child} #{parent.downcase!}:references #{attributes.join(" ")}"
      end

      # if needed, update the reference to the parent class name in the create_table migration
      current_transformer = Scaffolding::ClassNamesTransformer.new(child, parent, namespace)
      unless current_transformer.parent_variable_name_in_context.pluralize == current_transformer.parent_table_name
        replace_in_file(migration_file_name, "foreign_key: true", "foreign_key: {to_table: '#{current_transformer.parent_table_name}'}")
      end

      # update the factory generated by `rails g`.
      content = if transform_string(":absolutely_abstract_creative_concept") == transform_string(":scaffolding_absolutely_abstract_creative_concept")
        transform_string("association :absolutely_abstract_creative_concept")
      else
        transform_string("association :absolutely_abstract_creative_concept, factory: :scaffolding_absolutely_abstract_creative_concept")
      end

      scaffold_replace_line_in_file("./test/factories/scaffolding/completely_concrete/tangible_things.rb", content, "absolutely_abstract_creative_concept { nil }")

      add_has_many_association

      if class_names_transformer.belongs_to_needs_class_definition?
        scaffold_replace_line_in_file("./app/models/scaffolding/completely_concrete/tangible_thing.rb", transform_string("belongs_to :absolutely_abstract_creative_concept, class_name: \"Scaffolding::AbsolutelyAbstract::CreativeConcept\"\n"), transform_string("belongs_to :absolutely_abstract_creative_concept\n"))
      end

      update_models_abstract_class

      # add user permissions.
      add_ability_line_to_roles_yml
    end

    # Add factory setup in API controller test.
    unless cli_options["skip-api"]
      test_name = transform_string("./test/controllers/api/v1/scaffolding/completely_concrete/tangible_things_controller_test.rb")
      test_lines = File.open(test_name).readlines

      # Shift contents of controller test after skipping `unless scaffolding_things_disabled?` block.
      class_block_index = Scaffolding::FileManipulator.find(test_lines, "class #{transform_string("Api::V1::Scaffolding::CompletelyConcrete::TangibleThingsControllerTest")}")
      new_lines = Scaffolding::BlockManipulator.shift_block(lines: test_lines, block_start: test_lines[class_block_index], shift_contents_only: true)
      Scaffolding::FileManipulator.write(test_name, new_lines)

      # Ensure variables built with factories are indented properly.
      factory_hook_index = Scaffolding::FileManipulator.find(new_lines, RUBY_FACTORY_SETUP_HOOK)
      factory_hook_indentation = Scaffolding::BlockManipulator.indentation_of(factory_hook_index, new_lines)
      indented_factory_lines = build_factory_setup.map { |line| "#{factory_hook_indentation}#{line}\n" }
      scaffold_replace_line_in_file(test_name, indented_factory_lines.join, new_lines[factory_hook_index])
    end

    # add children to the show page of their parent.
    unless cli_options["skip-parent"] || parent == "None"
      scaffold_add_line_to_file(
        "./app/views/account/scaffolding/absolutely_abstract/creative_concepts/show.html.erb",
        "<%= render 'account/scaffolding/completely_concrete/tangible_things/index', tangible_things: @creative_concept.completely_concrete_tangible_things, hide_back: true %>",
        "<%# 🚅 super scaffolding will insert new children above this line. %>",
        prepend: true
      )
    end

    unless cli_options["skip-api"]
      # add children to the show page of their parent.
      scaffold_add_line_to_file(
        "./app/views/api/#{BulletTrain::Api.current_version}/open_api/index.yaml.erb",
        "<%= automatic_components_for Scaffolding::CompletelyConcrete::TangibleThing %>",
        "<%# 🚅 super scaffolding will insert new components above this line. %>",
        prepend: true
      )

      # add children to the show page of their parent.
      scaffold_add_line_to_file(
        "./app/views/api/#{BulletTrain::Api.current_version}/open_api/index.yaml.erb",
        "<%= automatic_paths_for Scaffolding::CompletelyConcrete::TangibleThing, Scaffolding::AbsolutelyAbstract::CreativeConcept %>",
        "<%# 🚅 super scaffolding will insert new paths above this line. %>",
        prepend: true
      )
    end

    unless cli_options["skip-model"]
      add_scaffolding_hooks_to_model
    end

    #
    # DELEGATIONS
    #

    unless cli_options["skip-model"]

      if ["Team", "User"].include?(parents.last) && parent != parents.last
        scaffold_add_line_to_file("./app/models/scaffolding/completely_concrete/tangible_thing.rb", "has_one :#{parents.last.underscore}, through: :absolutely_abstract_creative_concept", HAS_ONE_HOOK, prepend: true)
      end

    end

    add_attributes_to_various_views(attributes, type: :crud)

    unless cli_options["skip-locales"]
      add_locale_helper_export_fix
    end

    # add sortability.
    if cli_options["sortable"]
      scaffold_replace_line_in_file("./app/views/account/scaffolding/completely_concrete/tangible_things/_index.html.erb", transform_string("<tbody data-controller=\"sortable\" data-sortable-reorder-path-value=\"<%= url_for [:reorder, :account, context, collection] %>\">"), "<tbody>")

      unless cli_options["skip-model"]
        scaffold_add_line_to_file("./app/models/scaffolding/completely_concrete/tangible_thing.rb", "def collection\n  absolutely_abstract_creative_concept.completely_concrete_tangible_things\nend\n\n", METHODS_HOOK, prepend: true)
        scaffold_add_line_to_file("./app/models/scaffolding/completely_concrete/tangible_thing.rb", "include Sortable\n", CONCERNS_HOOK, prepend: true)

        migration = Dir.glob("db/migrate/*").last
        migration_lines = File.open(migration).readlines
        parent_line_idx = Scaffolding::FileManipulator.find(migration_lines, "t.references :#{parent.downcase}")
        new_lines = Scaffolding::BlockManipulator.insert_line("t.integer :sort_order", parent_line_idx, migration_lines, false)
        Scaffolding::FileManipulator.write(migration, new_lines)
      end

      unless cli_options["skip-controller"]
        scaffold_add_line_to_file("./app/controllers/account/scaffolding/completely_concrete/tangible_things_controller.rb", "include SortableActions\n", "Account::ApplicationController", increase_indent: true)
      end
    end

    # titleize the localization file.
    unless cli_options["skip-locales"]
      replace_in_file(transform_string("./config/locales/en/scaffolding/completely_concrete/tangible_things.en.yml"), child, child.underscore.humanize.titleize)
    end

    # apply routes.
    unless cli_options["skip-routes"]
      routes_namespace = cli_options["namespace"] || "account"

      begin
        routes_path = if routes_namespace == "account"
          "config/routes.rb"
        else
          "config/routes/#{routes_namespace}.rb"
        end
        routes_manipulator = Scaffolding::RoutesFileManipulator.new(routes_path, child, parent, cli_options)
      rescue Errno::ENOENT => _
        puts "Creating '#{routes_path}'.".green

        unless File.directory?("config/routes")
          FileUtils.mkdir_p("config/routes")
        end

        File.write(routes_path, <<~RUBY)
          collection_actions = [:index, :new, :create]

          # 🚅 Don't remove this block, it will break Super Scaffolding.
          begin
            namespace :#{routes_namespace} do
              shallow do
                resources :teams do
                end
              end
            end
          end
        RUBY

        retry
      end

      begin
        routes_manipulator.apply([routes_namespace])
        Scaffolding::FileManipulator.write(routes_path, routes_manipulator.lines)
      rescue => _
        add_additional_step :red, "We weren't able to automatically add your `#{routes_namespace}` routes for you. In theory this should be very rare, so if you could reach out on Slack, you could probably provide context that will help us fix whatever the problem was. In the meantime, to add the routes manually, we've got a guide at https://blog.bullettrain.co/nested-namespaced-rails-routing-examples/ ."
      end

      # If we're using a custom namespace, we have to make sure the newly
      # scaffolded routes are drawn in the `config/routes.rb` and API routes files.
      if cli_options["namespace"]
        draw_line = "draw \"#{routes_namespace}\""

        [
          "config/routes.rb",
          "config/routes/api/#{BulletTrain::Api.current_version}.rb"
        ].each do |routes_file|
          original_lines = File.readlines(routes_file)

          # Define which line we want to place the draw line under in the original routes files.
          insert_line = if routes_file.match?("api")
            draw_line = "  #{draw_line}" # Add necessary indentation.
            "namespace :v1 do"
          else
            "draw \"sidekiq\""
          end

          new_lines = Scaffolding::BlockManipulator.insert(draw_line, lines: original_lines, within: insert_line)
          Scaffolding::FileManipulator.write(routes_file, new_lines)
        end
      end

      unless cli_options["skip-api"]
        begin
          api_routes_manipulator = Scaffolding::RoutesFileManipulator.new("config/routes/api/#{BulletTrain::Api.current_version}.rb", child, parent, cli_options)
          api_routes_manipulator.apply([BulletTrain::Api.current_version.to_sym])
          Scaffolding::FileManipulator.write("config/routes/api/#{BulletTrain::Api.current_version}.rb", api_routes_manipulator.lines)
        rescue => _
          add_additional_step :red, "We weren't able to automatically add your `api/#{BulletTrain::Api.current_version}` routes for you. In theory this should be very rare, so if you could reach out on Slack, you could probably provide context that will help us fix whatever the problem was. In the meantime, to add the routes manually, we've got a guide at https://blog.bullettrain.co/nested-namespaced-rails-routing-examples/ ."
        end
      end
    end

    unless cli_options["skip-parent"]

      if top_level_model?
        icon_name = nil
        if cli_options["navbar"].present?
          icon_name = if cli_options["navbar"].match?(/^ti/)
            "ti #{cli_options["navbar"]}"
          elsif cli_options["navbar"].match?(/^fa/)
            "fal #{cli_options["navbar"]}"
          else
            puts ""
            puts "'#{cli_options["navbar"]}' is not a valid icon.".red
            puts "Please refer to the Themify or Font Awesome documentation and pass the value like so:"
            puts "--navbar=\"ti-world\""
            exit
          end
        else
          puts ""
          # TODO: Update this help text letting developers know they can Super Scaffold
          # models without a parent after the `--skip-parent` logic is implemented.
          puts "Hey, models that are scoped directly off of a Team are eligible to be added to the navbar."
          puts "Do you want to add this resource to the navbar menu? (y/N)"
          response = $stdin.gets.chomp
          if response.downcase[0] == "y"
            puts ""
            puts "OK, great! Let's do this! By default these menu items appear as a #{font_awesome? ? "puzzle piece" : "gift icon"},"
            puts "but after you hit enter I'll open #{font_awesome? ? "two different pages" : "a page"} where you can view other icon options."
            puts "When you find one you like, hover your mouse over it and then come back here and"
            puts "enter the name of the icon you want to use."
            puts "(Or hit enter when choosing to skip this step.)"
            $stdin.gets.chomp
            if TerminalCommands.can_open?
              TerminalCommands.open_file_or_link("https://themify.me/themify-icons")
              if font_awesome?
                TerminalCommands.open_file_or_link("https://fontawesome.com/icons?d=gallery&s=light")
              end
            else
              puts "Sorry! We can't open these URLs automatically on your platform, but you can visit them manually:"
              puts ""
              puts "  https://themify.me/themify-icons"
              if font_awesome?
                puts "  https://fontawesome.com/icons?d=gallery&s=light"
              end
              puts ""
            end
            puts ""

            loop do
              puts "Did you find an icon you wanted to use?"
              puts "Enter the full CSS class here (e.g. 'ti ti-world'#{" or 'fal fa-puzzle-piece'" if font_awesome?}) or hit enter to just use the #{font_awesome? ? "puzzle piece" : "gift icon"}:"
              icon_name = $stdin.gets.chomp
              unless icon_name.match?(/ti\s.*/) || icon_name.match?(/fal\s.*/) || icon_name.strip.empty?
                puts ""
                puts "Please enter the full CSS class or hit enter."
                next
              end
              break
            end
            puts ""
            unless icon_name.length > 0 || icon_name.downcase == "y"
              icon_name = "fal fa-puzzle-piece ti ti-gift"
            end
          end
        end
        if icon_name.present?
          replace_in_file(transform_string("./config/locales/en/scaffolding/completely_concrete/tangible_things.en.yml"), "fal fa-puzzle-piece", icon_name)
          scaffold_add_line_to_file("./app/views/account/shared/_menu.html.erb", "<%= render 'account/scaffolding/completely_concrete/tangible_things/menu_item' %>", "<% # added by super scaffolding. %>")
        end
      end
    end

    add_additional_step :yellow, transform_string("If you would like the table view you've just generated to reactively update when a Tangible Thing is updated on the server, please edit `app/models/scaffolding/absolutely_abstract/creative_concept.rb`, locate the `has_many :completely_concrete_tangible_things`, and add `enable_cable_ready_updates: true` to it.")

    restart_server unless ENV["CI"].present?
  end
end
