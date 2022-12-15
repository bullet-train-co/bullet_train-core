module Account::LocaleHelper
  def current_locale
    current_user.locale || current_team.locale || "en"
  end

  # as of now, we only calculate a possessive version of nouns in english.
  # if you're aware of another language where we can do this, please don't hesitate to reach out!
  def possessive_string(string)
    [:en].include?(I18n.locale) ? string.possessive : string
  end

  def model_locales(model)
    name = model.label_string.presence
    return {} unless name

    hash = {}
    prefix = model.class.name.split("::").last.underscore
    hash[:"#{prefix}_name"] = name
    hash[:"#{prefix.pluralize}_possessive"] = possessive_string(name)

    hash
  end

  def models_locales(*models)
    hash = {}
    models.compact.each do |model|
      hash.merge! model_locales(model)
    end
    hash
  end

  # this is a bit scary, no?
  def account_controller?
    controller.class.name.match(/^Account::/)
  end

  def t(key, options = {})
    # When bundled Ruby gems provide a lot of translations, it can be difficult to figure out which strings in the
    # application are coming from where. To help with this, you can add `?debug=true` to any URL and we'll output
    # any rendered strings and their translation keys on the console.
    unless Rails.env.production?
      if params.present?
        if params[:log_locales] || params[:show_locales]
          # Often times we're only receiving partial keys like `.section`, so this is a crazy hack to trick I18n.t into
          # telling us what the full key ended up being.
          begin
            super(key + "💣", options.except(:default))
          rescue I18n::MissingTranslationData => exception
            full_key = exception.message.rpartition(" ").last.delete("💣")
          end
        end
      end
    end

    if account_controller?
      # Give preference to the options they've passed in.
      options = models_locales(@child_object, @parent_object).merge(options)
    end

    result = super(key, options)

    unless Rails.env.production?
      if params.present?
        if params[:log_locales]
          if result == options[:default]
            puts "🌐 #{full_key}: Not found? Result matched default: \"#{result}\"".yellow
          else
            puts "🌐 #{full_key}: \"#{result}\"".green
          end
        end

        if params[:show_locales]
          return full_key
        end
      end
    end

    result
  end

  # like 't', but if the key isn't found, it returns nil.
  def ot(key, options = {})
    t(key, options)
  rescue I18n::MissingTranslationData => _
    nil
  end
end
