require "rake"

module Records::Base
  extend ActiveSupport::Concern

  included do
    if billing_enabled? && defined?(Billing::UsageSupport)
      include Billing::UsageSupport
    end

    if defined?(Webhooks::Outgoing::IssuingModel)
      include Webhooks::Outgoing::IssuingModel
    end

    if defined?(ObfuscatesId)
      include ObfuscatesId
    end

    if defined?(QuestionMethodsFromScopes)
      include QuestionMethodsFromScopes
    end

    include CableReady::Updatable
    enable_updates

    extend ActiveHash::Associations::ActiveRecordExtensions

    # 🏚 i'd like to deprecate these. they're not descriptive enough.
    scope :newest, -> { order("created_at DESC") }
    scope :oldest, -> { order("created_at ASC") }

    scope :newest_created, -> { order("created_at DESC") }
    scope :oldest_created, -> { order("created_at ASC") }
    scope :newest_updated, -> { order("updated_at DESC") }
    scope :oldest_updated, -> { order("updated_at ASC") }

    # TODO Probably we can provide a way for gem packages to define these kinds of extensions.
    if billing_enabled?
      # By default, any model in a collection is considered active for billing purposes.
      # This can be overloaded in the child model class to specify more specific criteria for billing.
      # See `app/models/concerns/memberships/base.rb` for an example.
      scope :billable, -> { order("TRUE") }
    end

    # Microscope adds useful scopes targeting ActiveRecord `boolean`, `date` and `datetime` attributes.
    # https://github.com/mirego/microscope
    acts_as_microscope
  end

  class_methods do
    # by default we represent methods by their first string attribute.
    def label_attribute
      columns_hash.values.find { |column| column.sql_type_metadata.type == :string }&.name
    end
  end

  # this is a template method you can override in activerecord models if we shouldn't just use their first string to
  # identify them.
  def label_string
    if (label_attribute = self.class.label_attribute)
      send("#{label_attribute}_was")
    else
      self.class.name.underscore.split("/").last.titleize
    end
  end

  def parent_collection
    # TODO Try to suggest what the entire method definition should actually be
    # using parent_key below to do so.
    model_name = self.class
    # parent_key = model_name.reflect_on_all_associations(:belongs_to).first.name
    raise "You're trying to use a feature that requires #{model_name} to have a `collection` method defined that returns the Active Record association that this model belongs to within its parent object."
  end

  def seeding?
    rake_tasks = ObjectSpace.each_object(Rake::Task)
    return false if rake_tasks.count.zero?

    db_seed_task = rake_tasks.find { |task| task.name.match?(/^db:seed$/) }
    db_seed_task.already_invoked
  end

  # TODO This should really be in the API package and included from there.
  if defined?(BulletTrain::Api)
    def to_api_json
      # TODO So many performance improvements available here.
      controller = "Api::#{BulletTrain::Api.current_version.upcase}::ApplicationController".constantize.new
      # TODO We need to fix host names here.
      controller.request = ActionDispatch::Request.new({})
      local_class_key = self.class.name.underscore.split("/").last.to_sym
      controller.render_to_string(
        "api/#{BulletTrain::Api.current_version}/#{self.class.name.underscore.pluralize}/_#{local_class_key}",
        locals: {
          local_class_key => self
        }
      )
    end
  end
end
