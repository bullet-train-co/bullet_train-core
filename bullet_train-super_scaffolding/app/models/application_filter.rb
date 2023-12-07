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

  private

  def condition(field, type)
    condition = CONDITIONS.fetch(type).new(field.to_s).with_display(heading(field))

    # Reject set/not_set clause options in case the field can't be null in the database.
    if (column = column_for(field))
      condition = condition.without_clauses([Clauses::SET, Clauses::NOT_SET]) if column.null == false
    end

    # Derive options via I18n scope.
    condition = condition.with_options(options_for(field)) if type == :option
    condition
  end

  def column_for(field)
    model.connection.columns(model.table_name).index_by(&:name)[field.to_s]
  end

  def heading(field)
    t("#{field}.heading")
  end

  def options_for(field)
    t("#{field}.options").map { {id: _1.to_s, display: _2} }
  end

  def t(key, **)
    I18n.t("#{i18n_scope}.fields.#{key}", **)
  end

  def i18n_scope
    @i18n_scope ||= self.class.name.chomp("::Filter").pluralize.underscore.tr("/", ".")
  end
end
