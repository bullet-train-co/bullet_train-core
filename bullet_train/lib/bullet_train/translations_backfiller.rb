module BulletTrain
  class TranslationsBackfiller
    def key_to_hash_with_value(key, value)
      keys = key.split(".")
      last_key = keys.pop
      result_hash = {}
      building_hash = result_hash
      keys.each do |key|
        new_hash = {}
        building_hash[key] = new_hash
        building_hash = new_hash
      end
      building_hash[last_key] = value
      result_hash
    end

    def register_defaults(subject, parent, value, key = nil)
      if value.is_a?(Hash)
        value.each do |child_key, child_value|
          register_defaults(subject, parent, child_value, [key, child_key].compact.join("."))
        end
      elsif value.is_a?(String)
        # Actually register the string.
        final_key = "#{subject.name.underscore.pluralize}.#{key}"
        final_value = value.gsub("%{subject}", I18n.t("#{subject.name.underscore.pluralize}.label").singularize)
        final_value = final_value.gsub("%{subjects}", I18n.t("#{subject.name.underscore.pluralize}.label"))
        final_value = final_value.gsub("%{subject_name}", "%{#{subject.name.underscore.split("/").last}_name}")
        final_value = final_value.gsub("%{parent_name}", "%{#{parent.name.underscore.split("/").last}_name}")
        final_value = final_value.gsub("%{parents_possessive}", "%{#{parent.name.underscore.split("/").last.pluralize}_possessive}")
        unless I18n.t(final_key, default: nil)
          I18n.backend.store_translations(:en, key_to_hash_with_value(final_key, final_value))
        end
      end
    end

    def all_models
      I18n.t(".").keys.map { |key|
        begin
          key.to_s.classify.constantize
        rescue
          nil
        end
      }.compact.select { |model| model < ApplicationRecord }
    end

    def register_all
      all_models.each do |subject|
        parent = I18n.t("#{subject.name.underscore.pluralize}.navigation.parent", default: nil)
        if parent
          register(subject, parent.classify.constantize)
        end
      end
    end

    def register(subject, parent)
      BulletTrain::TranslationsBackfiller.new.register_defaults(subject, parent, I18n.t("account.defaults"))

      I18n.backend.store_translations(:en, {
        subject.name.underscore.pluralize.to_s => {
          index: {
            contexts: {
              parent.name.underscore => I18n.t("#{subject.name.underscore.pluralize}.index.contexts.parent")
            }
          }
        }
      })

      I18n.backend.store_translations(:en, {
        subject.name.underscore.pluralize.to_s => {
          breadcrumbs: {
            label: I18n.t("#{subject.name.underscore.pluralize}.label")
          },
          navigation: {
            label: I18n.t("#{subject.name.underscore.pluralize}.label")
          }
        }
      })

      I18n.t("#{subject.name.underscore.pluralize}.fields").keys.each do |field|
        # TODO Don't overwrite values if they already exist.
        I18n.backend.store_translations(:en, {
          subject.name.underscore.pluralize.to_s => {
            fields: {
              field => {
                label: I18n.t("#{subject.name.underscore.pluralize}.fields.#{field}.heading")
              }
            }
          }
        })

        # TODO Don't overwrite values if they already exist.
        I18n.backend.store_translations(:en, {
          activerecord: {
            attributes: {
              subject.name.underscore.to_s => {
                field => I18n.t("#{subject.name.underscore.pluralize}.fields.#{field}.heading")
              }
            }
          }
        })
      end

      # Add buttons and fields to all the appropriate views.
      [:index, :show, :new, :edit, :form].each do |view|
        [:buttons, :fields].each do |section|
          values = I18n.t("#{subject.name.underscore.pluralize}.#{section}")
          I18n.backend.store_translations(:en, {
            subject.name.underscore.pluralize.to_s => {
              view => {
                section => values
              }
            }
          })
        end
      end

      # Copy to all the namespaces that are in play.
      [:account].each do |namespace|
        # TODO Would this overwrite existing values if they defined some?
        I18n.backend.store_translations(:en, key_to_hash_with_value("#{namespace}.#{subject.name.underscore.pluralize.tr("/", ".")}", I18n.t(subject.name.underscore.pluralize.to_s)))
      end
    end
  end
end
