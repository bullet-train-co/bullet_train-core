Note: before you attempt to manually wire up a `super_select` field, note that Super Scaffolding will automatically do that for your models. See [Super Scaffolding](/docs/super-scaffolding.md) docs, section 4, for an example. And make sure Super Scaffolding doesn't automatically do what you're trying to do.

# Examples for the `super_select` Field Partial

The `super_select` partial provides a wonderful default UI (in contrast to the vanilla browser experience for select boxes, which is horrible) with optional search and multi-select functionality out-of-the-box. It invokes the [Select2][select2] library to provide you these features.

## Define Available Buttons via Localization Yaml

If you invoke the field partial in `app/views/account/some_class_name/_form.html.erb` like so:

<pre><code><%= render 'shared/fields/super_select', form: form, method: :response_behavior %></code></pre>

You can define the available options in `config/locales/en/some_class_name.en.yml` like so:

<pre><code>en:
  some_class_name:
    fields:
      response_behavior:
        name: &response_behavior Response Behavior
        label: When should this object respond to new submissions?
        heading: Responds
        choices:
          immediate: Immediately
          after_10_minutes: After a 10 minute delay
          disabled: Doesn't respond
</code></pre>

## Specify Available Choices Inline

Although it's recommended to define any static list of choices in the localization Yaml file (so your application remains easy to translate into other languages), you can also specify these choices using the `choices` option from the underlying select form field helper:

<pre><code><%= render 'shared/fields/super_select', form: form, method: :response_behavior,
  choices: [['Immediately', 'immediate'],
  ['After a 10 minute delay', 'after_10_minutes'],
  ["Doesn't respond", 'disabled']] %></code></pre>

## Generate Choices Programmatically

You can generate the available buttons using a collection of database objects by passing the `options` option like so:

<pre><code><%= render 'shared/fields/super_select', form: form, method: :category_id,
  choices: Category.all.map { |category| [category.label_string, category.id] } %></code></pre>

## Allowing Multiple Option Selections

Here is an example allowing multiple team members to be assigned to a (hypothetical) `Project` model:

<pre><code><%= render 'shared/fields/super_select', form: form, method: :membership_ids,
  choices: @project.valid_memberships.map { |membership| [membership.name, membership.id] },
  html_options: {multiple: true} %>
</code></pre>

The `html_options` key is just inherited from the underlying Rails select form field helper.

## Allowing Search

Here is the same example, with search enabled:

<pre><code><%= render 'shared/fields/super_select', form: form, method: :membership_ids,
  choices: @project.valid_memberships.map { |membership| [membership.name, membership.id] },
  html_options: {multiple: true}, other_options: {search: true} %>
</code></pre>

## Accepting New Entries

Here is an example allowing a new option to be entered by the user:

<pre><code><%= render 'shared/fields/super_select', form: form, method: :delay_minutes,
  choices: %w(1 5 10 30).map { |value| [value, value] },
  other_options: {accepts_new: true} %>
</code></pre>

Note: this will set the option `value` (which will be submitted to the server) to the entered text.

To handle the new entry's text on the server, use `ensure_backing_models_on`.

`ensure_backing_models_on` validates an `id:` or multiple `ids:` against a passed Active Record relation, and yields for each missing id so you can create backing models. Like this:

```rb
if strong_params[:category_id]
  strong_params[:category_id] = ensure_backing_models_on(current_team.categories, id: strong_params[:category_id]) do |scope, id|
    scope.find_or_create_by(name: id)
  end
end
```

In case our form had `multiple: true`, we could have used `ids:` instead:

```rb
if strong_params[:category_ids]
  strong_params[:category_ids] = ensure_backing_models_on(current_team.categories, ids: strong_params[:category_ids]) do |scope, id|
    scope.find_or_create_by(name: id)
  end
end
```

Note, if you need to constrain the collection further you could pass any extra scope, e.g. `current_team.categories.not_archived`.


## Events

All events dispatched from the `super_select` partial are [Select2's jQuery events][select2_events] re-dispatched as native DOM events with the following caveats:

1. The native DOM event name is pre-pended with `$`
2. The original jQuery event is passed through under `event.detail.event`

| Select2 event name  | DOM event name       |
|---------------------|----------------------|
| change              | $change              |
| select2:closing     | $select2:closing     |
| select2:close       | $select2:close       |
| select2:opening     | $select2:opening     |
| select2:open        | $select2:open        |
| select2:selecting   | $select2:selecting   |
| select2:select      | $select2:select      |
| select2:unselecting | $select2:unselecting |
| select2:unselect    | $select2:unselect    |
| select2:clearing    | $select2:clearing    |
| select2:clear       | $select2:clear       |

For example, the view template for catching the `$change` events in a parent `dependent-form-fields` using a Stimulus controller with a single `updateDependentFields` method would look like this:

<pre><code>&lt;div data-controller="dependent-form-fields"&gt;
  &lt;div data-action="$change->dependent-form-fields#updateDependentFields"&gt;
    <%= render 'shared/fields/super_select', form: form, method: :category_id,
      choices: Category.all.map { |category| [category.label_string, category.id] } %>
  &lt;/div&gt;
  &lt;div&gt;
    &lt;!-- This is the dependent field that would get updated when the previous one changes --&gt;
    <%= render 'shared/fields/super_select', form: form, method: :category_id,
      choices: Category.all.map { |category| [category.label_string, category.id] },
      html_options: { data: { 'dependent-form-fields-target': 'dependentField' }} %>
  &lt;/div&gt;
&lt;/div&gt;</code></pre>

And this is an example of what the `dependent-form-fields` Stimulus controller would look like.

<pre><code>
// dependent_form_fields_controller.js
import { Controller } from "stimulus"

export default class extends Controller {
  static targets = [ "dependentField" ]

  updateDependentFields(event) {
    const originalSelect2Event = event.detail.event
    console.log(`catching event ${event.type}`, originalSelect2Event)

    this.dependentFieldTargets.forEach((dependentField) => {
      // update dependentField based on value found in originalSelect2Event.target.value
    })
  }
}
</code></pre>

[select2]: https://select2.org
[select2_events]: https://select2.org/programmatic-control/events

## Options
Select2 has different options available which you can check [here](https://select2.org/configuration/options-api).

You can pass these options to the super select partial like so:
```erb
<%= render 'shared/fields/super_select', method: :project,
  select2_options: {
    allowClear: true,
    placeholder: 'Your Custom Placeholder'
  }
%>
```

*Passing options like this doesn't allow JS callbacks or functions to be used, so you must extend the Stimulus controller and add options to the `optionsOverride` getter if you want to do so.

## Dynamically Updating Form Fields

If you'd like to:

* modify other fields based on the value of your `super_select`, or
* modify your `super_select` based on the value of other fields

See [Dynamic Forms and Dependent Fields](/docs/field-partials/dynamic-forms-dependent-fields.md).
