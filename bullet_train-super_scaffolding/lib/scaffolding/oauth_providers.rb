def oauth_scaffold_directory(directory, options)
  transformed_directory_name = oauth_transform_string(directory, options)
  empty_transformer = Scaffolding::Transformer.new("", "")
  begin
    Dir.mkdir(transformed_directory_name)
  rescue Errno::EEXIST => _
    puts "The directory #{transformed_directory_name} already exists, skipping generation.".yellow
  rescue Errno::ENOENT => _
    puts "Proceeding to generate '#{transformed_directory_name}'."
  end

  Dir.foreach(empty_transformer.resolve_template_path(directory)) do |file|
    file = "#{directory}/#{file}"
    unless File.directory?(empty_transformer.resolve_template_path(file))
      oauth_scaffold_file(file, options)
    end
  end
end

# there is a bunch of stuff duplicate here, but i'm OK with that for now.
def oauth_scaffold_file(file, options)
  transformed_file_name = oauth_transform_string(file, options)
  transformed_file_content = []
  empty_transformer = Scaffolding::Transformer.new("", "")

  skipping = false
  File.open(empty_transformer.resolve_template_path(file)).each_line do |line|
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
  empty_transformer = Scaffolding::Transformer.new("", "")

  # get these out of the way first.
  string = string.gsub("stripe_connect: Stripe", empty_transformer.encode_double_replacement_fix(options[:gems_provider_name] + ": " + name.titleize))
  string = string.gsub("ti-money", empty_transformer.encode_double_replacement_fix(options[:icon])) if options[:icon]
  string = string.gsub("omniauth-stripe-connect", empty_transformer.encode_double_replacement_fix(options[:omniauth_gem]))
  string = string.gsub("stripe_connect", empty_transformer.encode_double_replacement_fix(options[:gems_provider_name]))
  string = string.gsub("STRIPE_CLIENT_ID", empty_transformer.encode_double_replacement_fix(options[:api_key]))
  string = string.gsub("STRIPE_SECRET_KEY", empty_transformer.encode_double_replacement_fix(options[:api_secret]))

  # then try for some matches that give us a little more context on what they're looking for.
  string = string.gsub("stripe-account", empty_transformer.encode_double_replacement_fix(name.underscore.dasherize + "_account"))
  string = string.gsub("stripe_account", empty_transformer.encode_double_replacement_fix(name.underscore + "_account"))
  string = string.gsub("StripeAccount", empty_transformer.encode_double_replacement_fix(name + "Account"))
  string = string.gsub("Stripe Account", empty_transformer.encode_double_replacement_fix(name.titleize + " Account"))
  string = string.gsub("Stripe account", empty_transformer.encode_double_replacement_fix(name.titleize + " account"))
  string = string.gsub("with Stripe", empty_transformer.encode_double_replacement_fix("with " + name.titleize))

  # finally, just do the simplest string replace. it's possible this can produce weird results.
  # if they do, try adding more context aware replacements above, e.g. what i did with 'with'.
  string = string.gsub("stripe", empty_transformer.encode_double_replacement_fix(name.underscore))
  string = string.gsub("Stripe", empty_transformer.encode_double_replacement_fix(name))

  empty_transformer.decode_double_replacement_fix(string)
end

def oauth_scaffold_add_line_to_file(file, content, after, options, additional_options = {})
  empty_transformer = Scaffolding::Transformer.new("", "")
  file = oauth_transform_string(file, options)
  content = oauth_transform_string(content, options)
  after = oauth_transform_string(after, options)
  empty_transformer.add_line_to_file(file, content, after, additional_options)
end
