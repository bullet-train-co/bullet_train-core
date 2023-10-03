# Field Partials
Bullet Train includes a collection of view partials that are intended to [DRY-up](https://en.wikipedia.org/wiki/Don't_repeat_yourself) as much redundant presentation logic as possible for different types of form fields without taking on a third-party dependency like Formtastic.

## Responsibilities
These form field partials standardize and centralize the following behavior across all form fields that use them:

 - Apply theme styling and classes.
 - Display any error messages for a specific field inline under the field itself.
 - Display a stylized asterisk next to the label of fields that are known to be required.
 - Any labels, placeholder values, and help text are defined in a standardized way in the model's localization Yaml file.
 - For fields presenting a static list of options (e.g. a list of buttons or a select field) the options can be defined in the localization Yaml file.

It's a simple set of responsibilities, but putting them all together in one place cleans up a lot of form view code. One of the most compelling features of this "field partials" approach is that they're just HTML in ERB templates using standard Rails form field helpers within the standard Rails `form_with` method. That means there are no "last mile" issues if you need to customize the markup being generated. There's no library to fork or classes to override.

## The Complete Package
Each field partial can optionally include whichever of the following are required to fully support it:

 - **Controller assignment helper** to be used alongside Strong Parameters to convert whatever is submitted in the form to the appropriate ActiveRecord attribute value.
 - **Turbo-compatible JavaScript invocation** of any third-party library that helps support the field partial.
 - **Theme-compatible styling** to ensure any third-party libraries "fit in".
 - **Capybara testing helper** to ensure it's easy to inject values into a field partial in headless browser tests.

## Basic Usage
The form field partials are designed to be a 1:1 match for [the native Rails form field helpers](https://guides.rubyonrails.org/form_helpers.html) developers are already used to using. For example, consider the following basic Rails form field helper invocation:

```erb
<%= form.text_field :text_field_value, autofocus: true %>
```

Using the field partials, the same field would be implemented as follows:

```erb
<%= render 'shared/fields/text_field', form: form, method: :text_field_value, options: {autofocus: true} %>
```

At first blush it might look like a more verbose invocation, but that doesn't take into account that the first vanilla Rails example doesn't handle the field label or any other related functionality.

Breaking down the invocation:

 - `text_field` matches the name of the native Rails form field helper we want to invoke.
 - The `form` option passes a reference to the form object the field will exist within.
 - The `method` option specifies which attribute of the model the field represents, in the same way as the first parameter of the basic Rails `text_field` helper.
 - The `options` option is basically a passthrough, allowing you to specify options which will be passed directly to the underlying Rails form field helper.

The 1:1 relationship between these field partials and their underlying Rails form helpers is an important design decision. For example, the way `options` is passed through to native Rails form field helpers means that experienced Rails developers will still be able to leverage what they remember about using Rails, while those of us who don't readily remember all the various options of those helpers can make use of [the standard Rails documentation](https://guides.rubyonrails.org/form_helpers.html) and the great wealth of Rails code examples available online and still take advantage of these field partials. That means the amount of documentation we need to maintain for these field partials is strictly for those features that are in addition to what Rails provides by default.

Individual field partials might have additional options available based on the underlying Rails form field helper. Links to the documentation for individual form field partials are listed at the end of this page.

## `options` vs. `other_options`

Because Bullet Train field partials have more responsibilities than the underlying Rails form field helpers, there are also additional options for things like hiding labels, displaying specific error messages, etc. For these options, we pass them separately as `other_options`. This keeps them separate from the options in `options` that will be passed directly to the underlying Rails form field helper.

For example, to suppress a label on any field, we can use the `hide_label` option like so:

```erb
<%= render 'shared/fields/text_field', form: form, method: :text_field_value, other_options: {hide_label: true} %>
```

### Globally-Available `other_options` Options

| Key | Value Type | Description |
| --- | --- | --- |
| `help` | string | Display a specific help string. |
| `error` | string | Display a specific error string. |
| `hide_label` | boolean | Hide the field label. |
| `required` | boolean | Display an asterisk by the field label to indicate the field is required. |

## `required`: through presence validation vs. `options: {required: true}` vs. `other_options:{required: true}`

By default, where there's a presence validation on the model attribute, we add an asterisk to indicate the field is required. For fields without a presence validation, you have options to pass the `:required` detail:

1. `other_options: {required: true}` adds the asterisk to the field manually.
2. `options: {required: true}` adds asterisk but also triggers client-side validation via the [`required`](https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/required) attribute.

Since client-side validations vary from browser to browser, we recommend relying on server-side validation for most forms, and thus mostly using `other_options[:required]`.

## Reducing Repetition
When you're including multiple fields, you can DRY up redundant settings (e.g. `form: form`) like so:

```erb
<% with_field_settings form: form do %>
  <%= render 'shared/fields/text_field', method: :text_field_value, options: {autofocus: true} %>
  <%= render 'shared/fields/buttons', method: :button_value %>
  <%= render 'shared/fields/image', method: :cloudinary_image_value %>
<% end %>
```

## Field partials that integrate with third-party service providers
 - `image` makes it trivial to upload photos and videos to [Cloudinary](https://cloudinary.com) and store their resulting Cloudinary ID as an attribute of the model backing the form. To enable this field partial, sign up for Cloudinary and copy the "Cloudinary URL" they provide you with into your `config/application.yml` as `CLOUDINARY_URL`. If you use our [Heroku app.json](https://github.com/bullet-train-co/bullet_train/blob/main/app.json) to provision your production environment, this will happen in that environment automatically.

## Yaml Configuration
The localization Yaml file (where you configure label and option values for a field) is automatically generated when you run Super Scaffolding for a model. If you haven't done this yet, the localization Yaml file for `Scaffolding::CompletelyConcrete::TangibleThing` serves as a good example. Under `en.scaffolding/completely_concrete/tangible_things.fields` you'll see definitions like this:

```yaml
text_field_value:
  name: &text_field_value Text Field Value
  label: *text_field_value
  heading: *text_field_value
```

This might look redundant at first glance, as you can see that by default the same label ("Text Field Value") is being used for both the form field label (`label`) and the heading (`heading`) of the show view and table view. It's also used when the field is referred to in a validation error message. However, having these three values defined separately gives us the flexibility of defining much more user-friendly labels in the context of a form field. In my own applications, I'll frequently configure these form field labels to be much more verbose questions (in an attempt to improve the UX), but still use the shorter label as a column header on the table view and the show view:

```yaml
text_field_value:
  name: &text_field_value Text Field Value
  label: "What should the value of this text field be?"
  heading: *text_field_value
```

You can also configure some placeholder text (displayed in the field when in an empty state) or some inline help text (to be presented to users under the form field) like so:

```yaml
text_field_value:
  name: &text_field_value Text Field Value
  label: "What should the value of this text field be?"
  heading: *text_field_value
  placeholder: "Type your response here"
  help: "The value can be anything you want it to be!"
```

Certain form field partials like `buttons` and `super_select` can also have their selectable options configured in this Yaml file. See their respective documentation for details, as usage varies slightly.

## Available Field Partials

| Field Partial                                            | Data Type                 | Multiple Values? | Assignment Helpers      | JavaScript Library                                                                | Description                                                                                                                                              |
|----------------------------------------------------------|---------------------------|------------------|-------------------------|-----------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------|
| [`address_field`](/docs/field-partials/address-field.md) | `Address`                 |                  |                         |                                                                                   | Adds a block of address fields. On change, its country super-select auto-updates the state/province/region super-select and postal/zip code field label. |
| `boolean`                                                | `boolean`                 |                  | `assign_boolean`        |                                                                                   |                                                                                                                                                          |
| [`buttons`](/docs/field-partials/buttons.md)             | `string`                  | Optionally       | `assign_checkboxes`     |                                                                                   |                                                                                                                                                          |
| `image`                                                  | `string` or `attachment`* |                  |                         |                                                                                   |                                                                                                                                                          |
| `color_picker`                                           | `string`                  |                  |                         | [pickr](https://simonwep.github.io/pickr/)                                        |                                                                                                                                                          |
| `date_and_time_field`                                    | `datetime`                |                  |                         | [Date Range Picker](https://www.daterangepicker.com)                              |                                                                                                                                                          |
| `date_field`                                             | `date`                    |                  |                         | [Date Range Picker](https://www.daterangepicker.com)                              |                                                                                                                                                          |
| `email_field`                                            | `string`                  |                  |                         |                                                                                   |                                                                                                                                                          |
| `emoji_field`                                            | `string`                  |                  |                         | [Emoji Mart](https://missiveapp.com/open/emoji-mart) | A front-end library which allows users to browse and select emojis with ease. |                                                                                                       |
| [`file_field`](/docs/field-partials/file-field.md)       | `attachment`              |                  |                         | [Active Storage](https://edgeguides.rubyonrails.org/active_storage_overview.html) |                                                                                                                                                          |
| `options`                                                | `string`                  | Optionally       | `assign_checkboxes`     |                                                                                   |                                                                                                                                                          |
| `password_field`                                         | `string`                  |                  |                         |                                                                                   |                                                                                                                                                          |
| `phone_field`                                            | `string`                  |                  |                         | [International Telephone Input](https://intl-tel-input.com)                       | Ensures telephone numbers are in a format that can be used by providers like Twilio.                                                                     |
| [`super_select`](/docs/field-partials/super-select.md)   | `string`                  | Optionally       | `assign_select_options` | [Select2](https://select2.org)                                                    | Provides powerful option search, AJAX search, and multi-select functionality.                                                                            |
| `text_area`                                              | `text`                    |                  |                         |                                                                                   |                                                                                                                                                          |
| `text_field`                                             | `string`                  |                  |                         |                                                                                   |                                                                                                                                                          |
| `number_field`                                           | `integer`                 |                  |                         |                                                                                   |                                                                                                                                                          |
| `trix_editor`                                            | `text`                    |                  |                         | [Trix](https://github.com/basecamp/trix)                                          | Basic HTML-powered formatting features and support for at-mentions amongst team members.                                                                 |

* The data type for `image` fields will vary based on whether you're using Cloudinary or ActiveStorage.
For Cloudinary you should use `string`, and for ActiveStorage you should use `attachment`.

## A Note On Data Types
When creating a `multiple` option attribute, Bullet Train generates these values as a `jsonb`.
```
bin/super-scaffold crud Project Team multiple_buttons:buttons{multiple}
```

This will run the following rails command.
```
rails generate model Project team:references multiple_buttons:jsonb
```
## Formating `date` and `date_and_time`
After Super Scaffolding a `date` or `date_and_time` field, you can pass a format for the object like so:

```
<%= render 'shared/attributes/date', attribute: date_object, format: :short %>
```

Please refer to the [Ruby on Rails documentation](https://guides.rubyonrails.org/i18n.html#adding-date-time-formats) for more information.

## Dynamic Forms and Dependent Fields

To dynamically update your forms on field changes, Bullet Train introduces two new concepts:

1. Dependent Fields Pattern
2. Dependent Fields Frame

These concepts are currently used by the `address_field` to dynamically update the _State / Province / Region_ field on _Country_ change, as well as the label for the _Postal Code_ field.

[Read more about Dynamic Forms and Dependent Fields](/docs/field-partials/dynamic-forms-dependent-fields.md)

## Additional Field Partials Documentation
 - [`address_field`](/docs/field-partials/address-field.md)
 - [`buttons`](/docs/field-partials/buttons.md)
 - [`super_select`](/docs/field-partials/super-select.md)
 - [`file_field`](/docs/field-partials/file-field.md)
 - [`date_field` and `date_and_time_field`](/docs/field-partials/date-related-fields.md)
