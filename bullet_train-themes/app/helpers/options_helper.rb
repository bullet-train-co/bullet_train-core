module OptionsHelper
  # This tag provides a polymorphic way to handle the different types of options we support.
  # Please refer to the Ruby on Rails API for details concerning the methods and parameters we use here.
  #
  # check_box: https://api.rubyonrails.org/classes/ActionView/Helpers/FormBuilder.html#method-i-check_box
  # check_box_tag: https://api.rubyonrails.org/classes/ActionView/Helpers/FormTagHelper.html#method-i-check_box_tag
  # radio_button: https://api.rubyonrails.org/classes/ActionView/Helpers/FormBuilder.html#method-i-radio_button
  def options_tag(method, form:, options:, multiple:)
    options[:class] ||= "focus:ring-blue h-4 w-4 text-blue border-slate-300 dark:bg-slate-700#{" rounded" if multiple}"
    value = options.delete(:value)

    if multiple
      options[:multiple] = multiple
      options[:checked] = form.object.send(method).nil? ? nil : form.object.send(method).map(&:to_s).include?(value.to_s)
      unchecked_value = options.delete(:unchecked_value) || ""

      if form
        form.check_box method, options, value, unchecked_value
      else
        checked = !!options[:checked].delete
        check_box_tag method, checked, options
      end
    else
      form.radio_button method, value, options
    end
  end
end
