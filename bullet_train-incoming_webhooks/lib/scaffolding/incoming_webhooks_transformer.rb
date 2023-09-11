require "scaffolding"
require "scaffolding/transformer"

class Scaffolding::IncomingWebhooksTransformer < Scaffolding::Transformer
  attr_accessor :provider_name

  def initialize(provider_name, cli_options = {})
    super("", "", cli_options)
    self.provider_name = provider_name
  end

  def scaffold_incoming_webhook
    files = [
      "./app/models/webhooks/incoming/bullet_train_webhook.rb",
      "./app/controllers/webhooks/incoming/bullet_train_webhooks_controller.rb",
      "./test/controllers/webhooks/incoming/bullet_train_webhooks_controller_test.rb"
    ]

    files.each do |name|
      if File.directory?(resolve_template_path(name))
        scaffold_directory(name)
      else
        scaffold_file(name)
      end
    end

    file_name_hook = "bullet_train_webhook"
    new_model_file_name, _ = files.map { |file| file.gsub(file_name_hook, replacement_for(file_name_hook)) }

    # Set up the model's `verify_authenticity` method to return `true`.
    model_file_lines = File.readlines(new_model_file_name)
    comment_lines = [
      "# You can implement your authenticity verification logic in either\n",
      "# the newly scaffolded model or controller for your incoming webhooks.\n"
    ]
    lines_to_ignore = [
      "  # there are many ways a service might ask you to verify the validity of a webhook.\n",
      "  # whatever that method is, you would implement it here.\n"
    ]

    model_file_lines = File.readlines(new_model_file_name)
    new_model_file_lines = File.open(new_model_file_name).map.with_index do |line, idx|
      if line.match?("def verify_authenticity")
        indentation = Scaffolding::BlockManipulator.indentation_of(idx, model_file_lines)
        new_comment_lines = comment_lines.map { |comment_line| "#{indentation}#{comment_line}" }.join

        new_comment_lines +
          "#{line}" \
          "#{indentation}  true\n"
      elsif lines_to_ignore.include?(line)
        next
      else
        line
      end
    end

    Scaffolding::FileManipulator.write(new_model_file_name, new_model_file_lines)

    # Apply new routes
    begin
      [
        "config/routes.rb",
        # "config/routes/api/v1.rb"
      ].each do |routes_file|
        # Since the webhooks routes don't live under a parent resource, we can't use the `apply` method to apply routes.
        routes_manipulator = Scaffolding::RoutesFileManipulator.new(routes_file, "", "")
        resources_line = "  resources :#{replacement_for("bullet_train_webhooks")}"
        new_routes_lines = Scaffolding::BlockManipulator.insert(resources_line, lines: routes_manipulator.lines, after: "namespace :incoming")
        Scaffolding::FileManipulator.write(routes_file, new_routes_lines)
      end
    rescue BulletTrain::SuperScaffolding::CannotFindParentResourceException => exception
      add_additional_step :red, "We were not able to generate the routes for your Incoming Webhook automatically because: \"#{exception.message}\" You'll need to add them manually, which admittedly can be complicated. See https://blog.bullettrain.co/nested-namespaced-rails-routing-examples/ for guidance. 🙇🏻‍♂️"
    end
  end

  def transform_string(string)
    [
      "bullet_train_webhook",
      "Webhooks::Incoming::BulletTrainWebhook"
    ].each do |needle|
      string = string.gsub(needle, replacement_for(needle))
    end
    string
  end

  def replacement_for(string)
    case string
    when "bullet_train_webhook"
      "#{provider_name.tableize.singularize}_webhook"
    when "bullet_train_webhooks"
      "#{provider_name.tableize.singularize}_webhooks"
    when "Webhooks::Incoming::BulletTrainWebhook"
      "Webhooks::Incoming::#{provider_name}Webhook"
    end
  end
end
