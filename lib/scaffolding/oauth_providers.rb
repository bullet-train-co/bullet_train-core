def legacy_resolve_template_path(file)
  # Figure out the actual location of the file.
  # Originally all the potential source files were in the repository alongside the application.
  # Now the files could be provided by an included Ruby gem, so we allow those Ruby gems to register their base
  # path and then we check them in order to see which template we should use.
  BulletTrain::SuperScaffolding.template_paths.map do |base_path|
    base_path = Pathname.new(base_path)
    resolved_path = base_path.join(file).to_s
    File.exist?(resolved_path) ? resolved_path : nil
  end.compact.first || raise("Couldn't find the Super Scaffolding template for `#{file}` in any of the following locations:\n\n#{BulletTrain::SuperScaffolding.template_paths.join("\n")}")
end

def legacy_replace_in_file(file, before, after)
  puts "Replacing in '#{file}'." unless silence_logs?
  target_file_content = File.read(file)
  target_file_content.gsub!(before, after)
  File.write(file, target_file_content)
end

def legacy_add_line_to_file(file, content, hook, child, parent, options = {})
  increase_indent = options[:increase_indent]
  add_before = options[:add_before]
  add_after = options[:add_after]

  transformed_file_name = file
  transformed_content = content
  transform_hook = hook

  target_file_content = File.read(transformed_file_name)

  if target_file_content.include?(transformed_content)
    puts "No need to update '#{transformed_file_name}'. It already has '#{transformed_content}'."
  else
    new_target_file_content = []
    target_file_content.split("\n").each do |line|
      if /#{Regexp.escape(transform_hook)}\s*$/.match?(line)

        if add_before
          new_target_file_content << "#{line} #{add_before}"
        else
          unless options[:prepend]
            new_target_file_content << line
          end
        end

        # get leading whitespace.
        line =~ /^(\s*).*#{Regexp.escape(transform_hook)}.*/
        leading_whitespace = $1
        new_target_file_content << "#{leading_whitespace}#{"  " if increase_indent}#{transformed_content}"

        new_target_file_content << "#{leading_whitespace}#{add_after}" if add_after

        if options[:prepend]
          new_target_file_content << line
        end
      else
        new_target_file_content << line
      end
    end

    puts "Updating '#{transformed_file_name}'." unless silence_logs?

    File.write(transformed_file_name, new_target_file_content.join("\n") + "\n")
  end
end

def encode_double_replacement_fix(string)
  string.chars.join("~!@BT@!~")
end

def decode_double_replacement_fix(string)
  string.gsub("~!@BT@!~", "")
end

def oauth_scaffold_directory(directory, options)
  transformed_directory_name = oauth_transform_string(directory, options)
  begin
    Dir.mkdir(transformed_directory_name)
  rescue Errno::EEXIST => _
    puts "The directory #{transformed_directory_name} already exists, skipping generation.".yellow
  rescue Errno::ENOENT => _
    puts "Proceeding to generate '#{transformed_directory_name}'."
  end

  Dir.foreach(legacy_resolve_template_path(directory)) do |file|
    file = "#{directory}/#{file}"
    unless File.directory?(legacy_resolve_template_path(file))
      oauth_scaffold_file(file, options)
    end
  end
end

# there is a bunch of stuff duplicate here, but i'm OK with that for now.
def oauth_scaffold_file(file, options)
  transformed_file_name = oauth_transform_string(file, options)
  transformed_file_content = []

  skipping = false
  File.open(legacy_resolve_template_path(file)).each_line do |line|
    if line.include?("# 🚅 skip when scaffolding.")
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
        line = oauth_transform_string(line, options)
      end

      transformed_file_content << line

    end
  end
  transformed_file_content = transformed_file_content.join

  transformed_directory_name = File.dirname(transformed_file_name)
  unless File.directory?(transformed_directory_name)
    FileUtils.mkdir_p(transformed_directory_name)
  end

  puts "Writing '#{transformed_file_name}'." unless silence_logs?

  File.write(transformed_file_name, transformed_file_content)
end

def oauth_transform_string(string, options)
  name = options[:our_provider_name]

  # get these out of the way first.
  string = string.gsub("stripe_connect: Stripe", encode_double_replacement_fix(options[:gems_provider_name] + ": " + name.titleize))
  string = string.gsub("ti-money", encode_double_replacement_fix(options[:icon])) if options[:icon]
  string = string.gsub("omniauth-stripe-connect", encode_double_replacement_fix(options[:omniauth_gem]))
  string = string.gsub("stripe_connect", encode_double_replacement_fix(options[:gems_provider_name]))
  string = string.gsub("STRIPE_CLIENT_ID", encode_double_replacement_fix(options[:api_key]))
  string = string.gsub("STRIPE_SECRET_KEY", encode_double_replacement_fix(options[:api_secret]))

  # then try for some matches that give us a little more context on what they're looking for.
  string = string.gsub("stripe-account", encode_double_replacement_fix(name.underscore.dasherize + "_account"))
  string = string.gsub("stripe_account", encode_double_replacement_fix(name.underscore + "_account"))
  string = string.gsub("StripeAccount", encode_double_replacement_fix(name + "Account"))
  string = string.gsub("Stripe Account", encode_double_replacement_fix(name.titleize + " Account"))
  string = string.gsub("Stripe account", encode_double_replacement_fix(name.titleize + " account"))
  string = string.gsub("with Stripe", encode_double_replacement_fix("with " + name.titleize))

  # finally, just do the simplest string replace. it's possible this can produce weird results.
  # if they do, try adding more context aware replacements above, e.g. what i did with 'with'.
  string = string.gsub("stripe", encode_double_replacement_fix(name.underscore))
  string = string.gsub("Stripe", encode_double_replacement_fix(name))

  decode_double_replacement_fix(string)
end

def oauth_scaffold_add_line_to_file(file, content, after, options, additional_options = {})
  file = oauth_transform_string(file, options)
  content = oauth_transform_string(content, options)
  after = oauth_transform_string(after, options)
  legacy_add_line_to_file(file, content, after, nil, nil, additional_options)
end
