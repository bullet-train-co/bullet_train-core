class Scaffolding::IncomingWebhooksTransformer < Scaffolding::Transformer
  attr_accessor :provider_name

  def initialize(provider_name, cli_options = {})
    super("", "", cli_options)
    self.provider_name = provider_name
  end

  def scaffold_incoming_webhook
    files = [
      "./app/models/webhooks/incoming/bullet_train_webhook.rb",
      "./app/controllers/webhooks/incoming/bullet_train_webhooks_controller.rb"
    ]

    files.each do |name|
      if File.directory?(resolve_template_path(name))
        scaffold_directory(name)
      else
        scaffold_file(name)
      end
    end

    # Set up the model's `verify_authenticity` method to return `true`.
    model_file_lines = File.readlines("./app/models/webhooks/incoming/bullet_train_webhook.rb")
    verify_authenticity_line_number = Scaffolding::FileManipulator.find(model_file_lines, "def verify_authenticity", 0)
    comment_lines = [
      "# To verify authenticity, make sure you implement the logic in either",
      "# the newly scaffolded model or controller for your incoming webhooks.",
      "true"
    ]

    # TODO: The BlockManipulator works well with inserting one line at a time,
    # but spacing gets strange when working with multiple lines so I had to handle it manually here.
    new_model_file_lines = model_file_lines
    comment_lines.each_with_index do |line, idx|
      after_line, comment_indentation = if idx == 0
        ["def verify_authenticity", Scaffolding::BlockManipulator.indentation_of(verify_authenticity_line_number, model_file_lines)]
      else
        [comment_lines[idx - 1], ""]
      end

      new_model_file_lines = Scaffolding::BlockManipulator.insert(
        comment_indentation + line,
        lines: new_model_file_lines,
        after: after_line
      )
    end
    Scaffolding::FileManipulator.write("./app/models/webhooks/incoming/bullet_train_webhook.rb", new_model_file_lines)
  end

  def transform_string(string)
    [
      "Webhooks::Incoming::BulletTrainWebhook"
    ].each do |needle|
      string = string.gsub(needle, replacement_for(needle))
    end
    string
  end

  def replacement_for(string)
    case string
    when "Webhooks::Incoming::BulletTrainWebhook"
      "Webhooks::Incoming::#{provider_name}Webhook"
    end
  end
end
