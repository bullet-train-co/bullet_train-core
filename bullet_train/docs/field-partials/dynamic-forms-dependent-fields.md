# Dynamic Forms and Dependent Fields

Bullet Train introduces two new concepts to make your Hotwire-powered forms update dynamically on field changes.

1. Dependent Fields Pattern
2. Dependent Fields Frame

## Dependent Fields Pattern

Let's say we have a `super_select` for a "Where have you heard from us?" field. And we'll have a `text_field` for "Other", `disabled` by default.

```erb
<%= render 'shared/fields/super_select',
    method: :heard_from,
    options: {include_blank: true}, 
    other_options: {search: true}
%>
<%= render 'shared/fields/text_field',
    method: :heard_from_other,
    options: {disabled: true}
%>
```

Our goal: if `other` is selected, enable the "Other" field.

We'll wire the `super_select` field with the `dependable` Stimulus controller. We'll also tie both fields using the `dependable-dependents-selector-value`. In this case, the `id` of the the `heard_from_other` field.

```erb
<%= render 'shared/fields/super_select',
    method: :heard_from,
    options: {include_blank: true}, 
    other_options: {search: true},
    wrapper_options: {
      data: {
        'controller': "dependable",
        'action': '$change->dependable#updateDependents',
        'dependable-dependents-selector-value': "##{form.field_id(:heard_from_other)}"
      }
    }
%>
<%= render 'shared/fields/text_field',
    method: :heard_from_other,
    id: form.field_id(:heard_from_other),
    options: {disabled: true}
%>
```

On `$change` ([See `super_select` dispatched events](/docs/field-partials/super-select#events)), a custom `dependable:updated` event will be dispatched to all elements matching the `dependable-dependents-selector-value`. This gives us flexibility: disparate form fields don't need to be wrapped with a common Stimulus controlled-wrapper. This approach is favored over Stimulus `outlets` because here we're not coupling the functionality of the `dependable` and `dependent` fields. We're just dispatching Custom Events and using CSS selectors, preferably good old `form.field_id`'s.

To let our `:heard_from_other` field handle the `dependable:updated` event, we'll assume we have created a custom  `field-availability` Stimulus controller, with a `#toggle` method, looking for the `expected` value on the incoming event `target` element, in this case the `dependable` field.

```erb
<%= render 'shared/fields/text_field',
    method: :heard_from_other,
    id: form.field_id(:heard_from_other),
    options: {disabled: true},
    data: {
      controller: "field-availability",
      action: "dependable:updated->field-availability#toggle",
      field_availability_expected_value: "other"
    }
%>
```

Note: `field-availability` here is not implemented in Bullet Train. It serves as an example.

Next, we'll find a way to only serve the `:heard_from_other` field to the user if "other" is selected, this time by using server-side conditionals in a `turbo_frame`.

## Dependent Fields Frame

What if you'd instead want to:

* Not rely on a custom Stimulus controller to control the `disabled` state of the "Other" field
* Show/hide multiple dependent fields based on the value of the `dependable` field.
* Update more than the field itself, but also the value of its `label`. As an example, the [`address_field`](/docs/field-partials/address-field.md) partial shows an empty "State / Province / Region" sub-field by default, and on changing the `:country_id` field to the United States, changes the whole `:region_id` to "State" as its label and with all US States as its choices.

For these situations, Bullet Train has a `dependent_fields_turbo_frame` partial that's made to listen to `dependable:updated` events by default.

```erb
# update the super-select `dependable-dependents-selector-value` to "##{form.field_id(:heard_from, :dependent_fields)}" to match

<%= render "shared/fields/dependent_fields_frame", 
  id: form.field_id(:heard_from, :dependent_fields),
  form: form,
  dependable_fields: [:heard_from] do %>

  <% if form.object&.heard_from == "other" %>
    <%# no need for a custom `id` or the `disabled` attribute %>
    <%= render 'shared/fields/text_field', method: :heard_from_other %>
  <% end %>

  <%# include additional fields if "other" is selected %>
<% end %>
```

This `dependent_fields_frame` serves two purposes:

1. Handle the `dependable:updated` event, so that the frame can...
2. Re-fetch the current form URL (it could be for a `#new` or a `#edit`, it works in both situations) with a GET request (not a submit) that contains the `heard_from` value as a `query_string` param. It then ensures that our `form.object.heard_from` value gets populated with the value found in the `query_string` param automatically, with **no changes needed to the resource controller**. That's all handled by the `dependent_fields_frame` partial by reading its `dependable_fields` param.

With this functionality, the contents of the underlying `turbo_frame` will be populated with the updated fields.

---

Now let's say we want to come back to the `disabled` use case above, while using the `dependent_fields_frame` approach.

We'll move the conditional on the `disabled` property. And we'll also let the `dependent_fields_frame` underlying controller handle disabling the field automatically when the `turbo_frame` awaits updates.

```erb
<%= render "shared/fields/dependent_fields_frame", 
  id: form.field_id(:heard_from, :dependent_fields),
  form: form,
  dependable_fields: [:heard_from] do |dependent_fields_controller_name| %>

  <%= render 'shared/fields/text_field',
    method: :heard_from_other,
    options: {disabled: form.object&.heard_from != "other"},
    data: {"#{dependent_fields_controller_name}-target": "field"}
  %>
<% end %>
```

To learn more about its inner functionality, search the `bullet-train-core` repo for `dependable_controller.js`,  `dependent_fields_frame_controller.js` and `_dependent_fields_frame.html.erb`. You can also see an implementation by looking at the `_address_field.html.erb` partial.