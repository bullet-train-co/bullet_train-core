require "scaffolding/block_manipulator"

class Scaffolding::RoutesFileManipulator
  attr_accessor :child, :parent, :lines, :transformer_options, :concerns

  def initialize(filename, child, parent, transformer_options = {})
    @concerns = []
    self.child = child
    self.parent = parent
    @filename = filename
    self.lines = File.readlines(@filename)
    self.transformer_options = transformer_options
  end

  def child_parts
    @child_parts ||= child.underscore.pluralize.split("/")
  end

  def parent_parts
    @parent_parts ||= parent.underscore.pluralize.split("/")
  end

  def common_namespaces
    unless @common_namespaces
      @common_namespaces ||= []
      child_parts_copy = child_parts.dup
      parent_parts_copy = parent_parts.dup
      while child_parts_copy.first == parent_parts_copy.first && child_parts_copy.count > 1 && parent_parts_copy.count > 1
        @common_namespaces << child_parts_copy.shift
        parent_parts_copy.shift
      end
    end
    @common_namespaces
  end

  # def divergent_namespaces
  #   unless @divergent_namespaces
  #     @divergent_namespaces ||= []
  #     child_parts_copy = child_parts.dup
  #     parent_parts_copy = parent_parts.dup
  #     while child_parts_copy.first == parent_parts_copy.first
  #       child_parts_copy.shift
  #       parent_parts_copy.shift
  #     end
  #     child_parts_copy.pop
  #     parent_parts_copy.pop
  #     @divergent_namespaces = [child_parts_copy, parent_parts_copy]
  #   end
  #   @divergent_namespaces
  # end

  def divergent_parts
    unless @divergent_namespaces
      @divergent_namespaces ||= []
      child_parts_copy = child_parts.dup
      parent_parts_copy = parent_parts.dup
      while child_parts_copy.first == parent_parts_copy.first && child_parts_copy.count > 1 && parent_parts_copy.count > 1
        child_parts_copy.shift
        parent_parts_copy.shift
      end
      child_resource = child_parts_copy.pop
      parent_resource = parent_parts_copy.pop
      @divergent_namespaces = [child_parts_copy, child_resource, parent_parts_copy, parent_resource]
    end
    @divergent_namespaces
  end

  def find_namespaces(namespaces, within = nil)
    namespaces = namespaces.dup
    results = {}
    block_end = Scaffolding::BlockManipulator.find_block_end(starting_from: within, lines: lines) if within
    lines.each_with_index do |line, line_number|
      if within
        next unless line_number > within
        return results if line_number >= block_end
      end
      if line.include?("namespace :#{namespaces.first} do")
        results[namespaces.shift] = line_number
      end
      return results unless namespaces.any?
    end
    results
  end

  # TODO: Remove this and use the BlockManipulator
  def insert_before(new_lines, line_number, options = {})
    options[:indent] ||= false
    before = lines[0..(line_number - 1)]
    new_lines = new_lines.map { |line| (Scaffolding::BlockManipulator.indentation_of(line_number, lines) + (options[:indent] ? "  " : "") + line).gsub(/\s+$/, "") + "\n" }
    after = lines[line_number..]
    self.lines = before + (options[:prepend_newline] ? ["\n"] : []) + new_lines + after
  end

  # TODO: Remove this and use the BlockManipulator
  def insert_after(new_lines, line_number, options = {})
    options[:indent] ||= false
    before = lines[0..line_number]
    new_lines = new_lines.map { |line| (Scaffolding::BlockManipulator.indentation_of(line_number, lines) + (options[:indent] ? "  " : "") + line).gsub(/\s+$/, "") + "\n" }
    after = lines[(line_number + 1)..]
    self.lines = before + new_lines + (options[:append_newline] ? ["\n"] : []) + after
  end

  def insert_in_namespace(namespaces, new_lines, within = nil)
    namespace_lines = find_namespaces(namespaces, within)
    if namespace_lines[namespaces.last]
      block_start = namespace_lines[namespaces.last]
      insertion_point = Scaffolding::BlockManipulator.find_block_end(starting_from: block_start, lines: lines)
      insert_before(new_lines, insertion_point, indent: true, prepend_newline: (insertion_point > block_start + 1))
    else
      raise "we weren't able to insert the following lines into the namespace block for #{namespaces.join(" -> ")}:\n\n#{new_lines.join("\n")}"
    end
  end

  def find_or_create_namespaces(namespaces, within = nil)
    namespaces = namespaces.dup
    created_namespaces = []
    current_namespace = nil
    while namespaces.any?
      current_namespace = namespaces.shift
      namespace_lines = if within.nil?
        find_namespaces(created_namespaces + [current_namespace], within)
      else
        scope_namespace_to_parent(current_namespace, within)
      end

      unless namespace_lines[current_namespace]
        lines_to_add = ["namespace :#{current_namespace} do", "end"]
        if created_namespaces.any?
          insert_in_namespace(created_namespaces, lines_to_add, within)
        else
          insert(lines_to_add, within)
        end
      end
      created_namespaces << current_namespace
    end
    namespace_lines = find_namespaces(created_namespaces + [current_namespace], within)
    namespace_lines ? namespace_lines[current_namespace] : nil
  end

  # Since it's possible for multiple namespaces to exist on different levels,
  # We scope the namespace we're trying to scaffold to its proper parent before processing it.
  #
  # i.e:
  # Parent: Insight => Child: Personality::CharacterTrait
  # Parent: Team    => Child: Personality::Disposition
  # In this case, the :personality namespace under :insights should be
  # ignored when Super Scaffolding Personality::Dispositon.
  #
  # resources do :insights do
  #   namespace :personality do
  #     resources :character_traits
  #   end
  # end
  #
  # namespace :personality do
  #   resources :dispositions
  # end
  #
  # In this case, Personality::CharacterTrait is under Team just like Personality::Disposition,
  # but Personality::CharacterTrait's DIRECT parent is Insight so we shouldn't scaffold its routes there.
  def scope_namespace_to_parent(namespace, within)
    namespace_block_start = namespace_blocks_directly_under_parent(within).map do |namespace_block|
      namespace_line_number = namespace_block.begin
      namespace_line_number if lines[namespace_line_number].match?(/ +namespace :#{namespace}/)
    end.compact
    namespace_block_start.present? ? {namespace => namespace_block_start} : {}
  end

  def find_in_namespace(needle, namespaces, within = nil, ignore = nil)
    if namespaces.any?
      namespace_lines = find_namespaces(namespaces, within)
      within = namespace_lines[namespaces.last]
    end

    Scaffolding::FileManipulator.lines_within(lines, within).each_with_index do |line, line_number|
      # + 2 because line_number starts from 0, and within starts one line after
      actual_line_number = (within + line_number + 2)

      # The lines we want to ignore may be a a series of blocks, so we check each Range here.
      ignore_line = false
      if ignore.present?
        ignore.each do |lines_to_ignore|
          ignore_line = true if lines_to_ignore.include?(actual_line_number)
        end
      end

      next if ignore_line
      return (within + (within ? 1 : 0) + line_number) if line.match?(needle)
    end

    nil
  end

  def find_resource_block(parts, options = {})
    within = options[:within]
    parts = parts.dup
    resource = parts.pop
    # TODO this doesn't take into account any options like we do in `find_resource`.
    find_in_namespace(/resources :#{resource}#{options[:options] ? ", #{options[:options].gsub(/({)(.*)(})/, '{\2}')}" : ""}(,?\s.*)? do(\s.*)?$/, parts, within)
  end

  def find_resource(parts, options = {})
    parts = parts.dup
    resource = parts.pop
    needle = /resources :#{resource}#{options[:options] ? ", #{options[:options].gsub(/({)(.*)(})/, '{\2}')}" : ""}(,?\s.*)?$/
    find_in_namespace(needle, parts, options[:within], options[:ignore])
  end

  def find_or_create_resource(parts, options = {})
    parts = parts.dup
    resource = parts.pop
    namespaces = parts
    namespace_within = find_or_create_namespaces(namespaces, options[:within])

    # The namespaces that the developer has declared are captured above in `namespace_within`,
    # so all other namespaces nested inside the resource's parent should be ignored.
    options[:ignore] = top_level_namespace_block_lines(options[:within]) || []

    unless (result = find_resource([resource], options))
      result = insert(["resources :#{resource}" + (options[:options] ? ", #{options[:options]}" : "")], namespace_within || options[:within])
    end
    result
  end

  # Finds namespace blocks no matter how many levels deep they are nested in resource blocks, etc.
  # However, will not find namespace blocks inside namespace blocks.
  def top_level_namespace_block_lines(within)
    local_namespace_blocks = []
    Scaffolding::FileManipulator.lines_within(lines, within).each do |line|
      # i.e. - Retrieve "foo" from "namespace :foo do"
      match_data = line.match(/(\s*namespace\s:)(.*)(\sdo$)/)

      # Since we only want top-level namespace blocks, we ensure that
      # all other namespace blocks INSIDE the top-level namespace blocks are skipped
      if match_data.present?
        namespace_name = match_data[2]
        local_namespace = find_namespaces([namespace_name], within)
        starting_line_number = local_namespace[namespace_name]
        local_namespace_block = ((starting_line_number + 1)..(Scaffolding::BlockManipulator.find_block_end(starting_from: starting_line_number, lines: lines) + 1))

        if local_namespace_blocks.empty?
          local_namespace_blocks << local_namespace_block
        else
          skip_block = false
          local_namespace_blocks.each do |block_range|
            if block_range.include?(local_namespace_block.first)
              skip_block = true
            else
              next
            end
          end
          local_namespace_blocks << local_namespace_block unless skip_block
        end
      end
    end

    local_namespace_blocks
  end

  # Whereas top_level_namespace_block_lines grabs all namespace blocks that
  # appear first no matter how many resource blocks they're nested in,
  # this method grabs namespace blocks that are only indented one level deep.
  def namespace_blocks_directly_under_parent(within)
    blocks = []
    if lines[within].match?(/do$/)
      parent_indentation_size = Scaffolding::BlockManipulator.indentation_of(within, lines).length
      within_block_end = Scaffolding::BlockManipulator.find_block_end(starting_from: within, lines: lines)
      within.upto(within_block_end) do |line_number|
        if lines[line_number].match?(/^#{" " * (parent_indentation_size + 2)}namespace/)
          namespace_block_lines = line_number..Scaffolding::BlockManipulator.find_block_end(starting_from: line_number, lines: lines)
          blocks << namespace_block_lines
        end
      end
    end
    blocks
  end

  def find_or_create_resource_block(parts, options = {})
    find_or_create_resource(parts, options)
    find_or_convert_resource_block(parts.last, options)
  end

  def find_or_convert_resource_block(parent_resource, options = {})
    unless find_resource_block([parent_resource], options)
      if (resource_line_number = find_resource([parent_resource], options))
        # convert it.
        lines[resource_line_number].gsub!("\n", " do\n")
        insert_after(["end"], resource_line_number)
      else
        raise BulletTrain::SuperScaffolding::CannotFindParentResourceException.new("the parent resource (`#{parent_resource}`) doesn't appear to exist in `#{@filename}`.")
      end
    end

    # update the block of code we're working within.
    unless (within = find_resource_block([parent_resource], options))
      raise "tried to convert the parent resource to a block, but failed?"
    end

    within
  end

  # TODO: Remove this and use the BlockManipulator
  def insert(lines_to_add, within)
    insertion_line = Scaffolding::BlockManipulator.find_block_end(starting_from: within, lines: lines)
    result_line = insertion_line
    unless insertion_line == within + 1
      # only put the extra space if we're adding this line after a block
      if /^\s*end\s*$/.match?(lines[insertion_line - 1])
        lines_to_add.unshift("")
        result_line += 1
      end
    end
    insert_before(lines_to_add, insertion_line, indent: true)
    result_line
  end

  def apply(base_namespaces)
    child_namespaces, child_resource, parent_namespaces, parent_resource = divergent_parts

    within = find_or_create_namespaces(base_namespaces)

    # e.g. Project and Projects::Deliverable
    if parent_namespaces.empty? && child_namespaces.one? && parent_resource == child_namespaces.first

      # resources :projects do
      #   scope module: 'projects' do
      #     resources :deliverables, only: collection_actions
      #   end
      # end

      parent_within = find_or_convert_resource_block(parent_resource, within: within)

      # add the new resource within that namespace.
      line = "scope module: '#{parent_resource}' do"
      # TODO you haven't tested this yet.
      unless (scope_within = Scaffolding::FileManipulator.find(lines, /#{line}/, parent_within))
        scope_within = insert([line, "end"], parent_within)
      end

      find_or_create_resource([child_resource], options: "only: collection_actions", within: scope_within)

      # namespace :projects do
      #   resources :deliverables, except: collection_actions
      # end

      # We want to see if there are any namespaces one level above the parent itself,
      # because namespaces with the same name as the resource can exist on the same level.
      parent_block_start = Scaffolding::BlockManipulator.find_block_parent(parent_within, lines)
      namespace_line_within = find_or_create_namespaces(child_namespaces, parent_block_start)
      find_or_create_resource([child_resource], options: "except: collection_actions", within: namespace_line_within)
      unless find_namespaces(child_namespaces, within)[child_namespaces.last]
        raise "tried to insert `namespace :#{child_namespaces.last}` but it seems we failed"
      end

    # e.g. Projects::Deliverable and Objective Under It, Abstract::Concept and Concrete::Thing
    elsif parent_namespaces.any?

      # namespace :projects do
      #   resources :deliverables
      # end
      top_parent_namespace = find_namespaces(parent_namespaces, within)[parent_namespaces.first]
      find_or_create_resource(child_namespaces + [child_resource], within: top_parent_namespace)

      # resources :projects_deliverables, path: 'projects/deliverables' do
      #   resources :objectives
      # end
      block_parent_within = Scaffolding::BlockManipulator.find_block_parent(top_parent_namespace, lines)
      parent_namespaces_and_resource = (parent_namespaces + [parent_resource]).join("_")
      parent_within = find_or_create_resource_block([parent_namespaces_and_resource], options: "path: '#{parent_namespaces_and_resource.tr("_", "/")}'", within: block_parent_within)
      find_or_create_resource(child_namespaces + [child_resource], within: parent_within)
    else

      begin
        within = find_or_convert_resource_block(parent_resource, within: within)
      rescue
        within = find_or_convert_resource_block(parent_resource, options: "except: collection_actions", within: within)
      end

      add_concern(:sortable) if transformer_options["sortable"]
      find_or_create_resource(child_namespaces + [child_resource], options: formatted_concerns, within: within)

    end
  end

  def add_concern(concern)
    @concerns.push(concern)
  end

  def formatted_concerns
    return if @concerns.empty?
    "concerns: #{@concerns}"
  end

  # Adds a concern to an existing resource at the given line number. (used by the audit logs gem)
  def add_concern_at_line(concern, line_number)
    line = lines[line_number]
    existing_concerns = line.match(/concerns: \[(.*)\]/).to_a[1].to_s.split(",")
    existing_concerns.map! { |e| e.tr(":", "").tr("\"", "").squish&.to_sym }
    existing_concerns.filter! { |e| e.present? }
    existing_concerns << concern
    if line.include?("concerns:")
      lines[line_number].gsub!(/concerns: \[(.*)\]/, "concerns: [#{existing_concerns.map { |e| ":#{e}" }.join(", ")}]")
    elsif line.ends_with?(" do")
      lines[line_number].gsub!(/ do$/, " concerns: [#{existing_concerns.map { |e| ":#{e}" }.join(", ")}] do")
    else
      lines[line_number].gsub!(/resources :(.*)$/, "resources :\\1, concerns: [#{existing_concerns.map { |e| ":#{e}" }.join(", ")}]")
    end
  end
end
