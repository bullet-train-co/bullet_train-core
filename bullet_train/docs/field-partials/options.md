# Field Partial Options
Most field partials have a native Rails form helper working underneath. To see what options you can pass to a partial, check the API for the form helper you want to edit.

In addition, Bullet Train provides framework-specific options which you can pass as `other_options` to further customize your fields.

## General `other_options` Types
Some partials have specific types of `other_options` available for only that partial. However, the following `other_options` are available for all field partials, and you can pass them to a field partial like this.

```erb
<%= render 'shared/fields/text_field' method: :attribute_name, other_options: {help: "Custom help text"} %>
```

| Key | Description |
|-----|-------------|
| `:help` | Pass a String to display help text |
| `:error` | Pass a String to write a custom error and outline the field in red |
| `:required` | Pass a Boolean to make this field required or not |
| `:label` | Pass a String to display a custom label |
| `:hide_label` | Pass a Boolean to hide the label |
| `:hide_custom_error` | Highlight the erroneous field in red, but hide the error message set in `:error` |
| `:icon` | Add a custom icon as an HTML class (i.e. - `ti ti-tablet`)|

## `other_options` for Specific Field Partials
| Partial Name | Option            | Description
|--------------|-------------------|-----------------| 
| `password_field` | `:show_strength_indicator`* | Shows how strong the password is via a Stimulus controller with the colors red, yellow, and green. |
| `super_select` | Refer to the [super_select documentation](/docs/field-partials/super-select.md) | Super Select fields have different kinds of options which are covered in another page. |


*Currently, you must pass `:show_strength_indicator` to `options`, not `other_options`. This will change in a later version.

## Field Partial Form Helpers

Most of the field partials have a native Rails form helper working underneath. Please use `bin/resolve` if you want to look at the source code for the partial (i.e. - `bin/resolve shared/fields/text_field`).

| Partial Name | Rails Form Helper |
|--------------|-------------------|
| `address_field` | [select](https://api.rubyonrails.org/classes/ActionView/Helpers/FormBuilder.html#method-i-select) |
| `boolean` | [radio_button](https://api.rubyonrails.org/classes/ActionView/Helpers/FormBuilder.html#method-i-radio_button) |
| `buttons` | [radio_button](https://api.rubyonrails.org/classes/ActionView/Helpers/FormBuilder.html#method-i-radio_button) ([check_box](https://api.rubyonrails.org/classes/ActionView/Helpers/FormBuilder.html#method-i-check_box) when `options[:multiple]` is `true`) |
| `image` | [file_field](https://api.rubyonrails.org/classes/ActionView/Helpers/FormHelper.html#method-i-file_field) when using ActiveStorage (No Rails form helper is called when using Cloudinary) |
| `color_picker` | [hidden_field](https://api.rubyonrails.org/classes/ActionView/Helpers/FormHelper.html#method-i-hidden_field) (Currently cannot edit this field) |
| `date_and_time_field` | [text_field](https://api.rubyonrails.org/classes/ActionView/Helpers/FormHelper.html#method-i-text_field) |
| `date_field` | [text_field](https://api.rubyonrails.org/classes/ActionView/Helpers/FormHelper.html#method-i-text_field) |
| `email_field` | [email_field](https://api.rubyonrails.org/classes/ActionView/Helpers/FormHelper.html#method-i-email_field) |
| `emoji_field` | [hidden_field](https://api.rubyonrails.org/classes/ActionView/Helpers/FormHelper.html#method-i-hidden_field) (Currently cannot edit this field) |
| `options` | [radio_button](https://api.rubyonrails.org/classes/ActionView/Helpers/FormBuilder.html#method-i-radio_button) ([check_box](https://api.rubyonrails.org/classes/ActionView/Helpers/FormBuilder.html#method-i-check_box) when `options[:multiple]` is `true`) |
| `password_field` | [password_field](https://api.rubyonrails.org/classes/ActionView/Helpers/FormHelper.html#method-i-password_field) |
| `phone_field` | [text_field](https://api.rubyonrails.org/classes/ActionView/Helpers/FormHelper.html#method-i-text_field) |
| `super_select` | [select](https://api.rubyonrails.org/classes/ActionView/Helpers/FormBuilder.html#method-i-select) |
| `text_area` | [text_area](https://api.rubyonrails.org/classes/ActionView/Helpers/FormHelper.html#method-i-text_area) |
| `text_field` | [text_field](https://api.rubyonrails.org/classes/ActionView/Helpers/FormHelper.html#method-i-text_field) |
| `number_field` | [number_field](https://api.rubyonrails.org/classes/ActionView/Helpers/FormHelper.html#method-i-number_field) |
| `trix_editor` | [rich_text_editor](https://api.rubyonrails.org/classes/ActionView/Helpers/FormHelper.html#method-i-rich_text_area) |
| `code_editor` | [text_area](https://api.rubyonrails.org/classes/ActionView/Helpers/FormHelper.html#method-i-text_area) |