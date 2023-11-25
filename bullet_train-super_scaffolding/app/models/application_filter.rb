class ApplicationFilter < Refine::Filter
  include Refine::Conditions

  CONDITIONS = {
    option: OptionCondition,
    numeric: NumericCondition,
    text: TextCondition,
    boolean: BooleanCondition,
    date: DateCondition,
    datetime: DateWithTimeCondition,
  }

  # list conditions in alphabetical order
  def conditions_to_array
    super&.sort_by { _1[:display].to_s.downcase }
  end

  def empty_option
    [{id: "null", display: "Empty"}]
  end

  # Helper method used in certain applications of invalid filter checks. This will
  def empty_query
    model.where("1 = 0")
  end

  private

  def condition(field, type)
    CONDITIONS.fetch(type).new(field.to_s).with_display(heading(field)).then do
      type == :option ? _1.with_options(options_for(field)) : _1
    end
  end


  def heading(field)
    t("#{field}.heading")
  end

  def options_for(field)
    t("#{field}.options").map { { id: _1.to_s, display: _2 } }
  end

  def t(key, **options)
    I18n.t("#{i18n_scope}.fields.#{key}", **options)
  end

  def i18n_scope
    @i18n_scope ||= self.class.name.chomp("::Filter").pluralize.underscore.gsub("/", ".")
  end
end
