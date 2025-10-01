# Super Scaffolding with the `--sortable` option

<div class="rounded-md border bg-amber-100 border-amber-200 py-4 px-5 mb-3 not-prose">
  <h3 class="text-sm text-amber-800 font-light mb-2">
    Note: The sortable controller and these docs have recently changed.
  </h3>
  <p class="text-sm text-amber-800 font-light mb-2">
    These instructions are for the new `sortable_controller.js` which has removed the dependency on `dragula` and which works slightly differently.
  </p>
  <p class="text-sm text-amber-800 font-light">
    <a href="/docs/super-scaffolding/dragula-sortable">You can find the old documentation for the `dragula` based controller here.</a>
  </p>
</div>

When issuing a `rails generate super_scaffold` command, you can pass the `--sortable` option like this:

```
# E.g. Pages belong to a Site and are sortable via drag-and-drop:
rails generate super_scaffold Page Site,Team name:text_field path:text_area --sortable
```

The `--sortable` option:

1. Wraps the table's body in a `sortable` Stimulus controller, providing drag-and-drop re-ordering;
2. Adds a `reorder` action to your resource via `include SortableActions`, triggered automatically on re-order;
3. Adds a `sort_order` attribute to your model to store the ordering;
4. Adds a `default_scope` which orders by `sort_order` and auto increments `sort_order` on create via `include Sortable` on the model.

## Disabling Saving on Re-order

By default, a call to save the new `sort_order` is triggered automatically on re-order.

### To disable auto-saving

Add the  `data-sortable-save-on-reorder-value="false"` param on the `sortable` root element:

```html
<tbody data-controller="sortable"
  data-sortable-save-on-reorder-value="false"
  ...
>
```

### To manually fire the save action via a button

Since the button won't be part of the `sortable` root element's descendants (all its direct descendants are sortable by default), you'll need to wrap both the `sortable` element and the save button in a new Stimulus controlled ancestor element. On the button, add a `data-action`.

For instance:

```html
<div data-controller="sortable-wrapper">
    <table>...</table>
    <button data-action="sortable-wrapper#saveSortOrder">Save Sort Order</button>
</div>
```

```js
/* sortable-wrapper_controller.js */
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "sortable" ]

  saveSortOrder() {
    if (!this.hasSortableTarget) { return }
    this.sortableTarget.dispatchEvent(new CustomEvent("save-sort-order"))
  }
}
```

And on the `sortable` element, catch the `save-sort-order` event and define it as the `sortable` target for the `sortable-wrapper` controller:

```html
<tbody data-controller="sortable"
  data-sortable-save-on-reorder-value="false"
  data-action="save-sort-order->sortable#saveSortOrder"
  data-sortable-wrapper-target="sortable"
  ...
>
```

## Events

Under the hood, the `sortable` Stimulus controller uses native drag and drop event handling as provided by modern browsers.

The following events are dispatched when significant events related to the list occur. (Note these are new events that were not previously emitted by the `dragula` based controller.)

| Event name         | Fired when                                          |
|--------------------|-----------------------------------------------------|
| sortable:start     | a drag via drag handle is started                   |
| sortable:reordered | the items in the list are reorderd during a drag    |
| sortable:end       | a sortable item is released                         |
| sortable:saved     | the new order has been persisted after a drop       |

These are events that we'll emit to retain some backwards compatibility with the old `dragula` based controller. Be aware that they may not behave exactly the same. In general you should prefer the events above.

| Event name       | Fired when                                         | Better option      |
|------------------|----------------------------------------------------|--------------------|
| sortable:drag    | a drag via drag handle is started                  | sortable:start     |
| sortable:dragend | a sortable item is released                        | sortable:end       |
| sortable:drop    | a sortable item is released                        | sortable:end       |
| sortable:shadow  | the items in the list are reorderd during a drag   | sortable:reordered |

**Note**: The old `dragula` based controller used to emit a few events that were particular to `dragula`. The new controller **does not** emit the following events:

| event name           |
|----------------------|
| sortable:cancel      |
| sortable:remove      |
| sortable:over        |
| sortable:out         |
| sortable:cloned      |

### Example: Asking for Confirmation on the `drop` Event

Let's say we'd like to ask the user to confirm before saving the new sort order:

> Are you sure you want to place DROPPED ITEM before SIBLING ITEM?

Add a `data-controller` attribute to the `<table>` tag that wraps the sortable `<tbody>`:

```html
<table data-controller="confirm-reorder">
```

```js
/* confirm-reorder_controller.js */
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "sortable" ]

  requestConfirmation(event) {
    const [el, target, source, sibling] = event.detail?.args

    // sibling will be undefined if dropped in last position, taking a shortcut here
    const areYouSure = `Are you sure you want to place ${el.dataset.name} before ${sibling.dataset.name}?`

    // let's suppose each <tr> in sortable has a data-name attribute
    if (confirm(areYouSure)) {
      this.sortableTarget.dispatchEvent(new CustomEvent('save-sort-order'))
    } else {
      this.revertToOriginalOrder()
    }
  }

  prepareForRevertOnCancel(event) {
    // we're assuming we can swap out the HTML safely
    this.originalSortableHTML = this.sortableTarget.innerHTML
  }

  revertToOriginalOrder() {
    if (this.originalSortableHTML === undefined) { return }
    this.sortableTarget.innerHTML = this.originalSortableHTML
    this.originalSortableHTML = undefined
  }
}
```

And on the `sortable` element, catch the `sortable:end`, `sortable:start` (for catching when dragging starts) and `save-sort-order` events. Also define it as the `sortable` target for the `confirm-reorder` controller:

```html
<tbody data-controller="sortable"
  data-sortable-save-on-reorder-value="false"
  data-action="sortable:end->confirm-reorder#requestConfirmation sortable:start->confirm-reorder#prepareForRevertOnCancel save-sort-order->sortable#saveSortOrder"
  data-confirm-reorder-target="sortable"
  ...
>
```

## Drag handles

With the release of the new `sortable_controller` new super scaffolds will include a cell at the begining of each row with an icon as a drag handle.

For pre-existing super scaffolds the new controller will detect that the handles are missing and it will programatically add them to the table.

If you want more control over the handles you should update your tempaltes to include handles, which will prevent them from being automatically added.

Using the example of a sortable `Page` model from above you'll want to update two files.

### `app/views/account/pages/_index.html.erb`

In `app/views/account/pages/_index.html.erb` you should add an empty `<td>` as the first cell within the `<tr>` in the `<thead>`. You probably want to set a width for that cell to make things look nice.

```html
<thead>
    <tr>
        <th class="w-6"></th> <!-- Add this line! -->
        <!-- Your existing cells here -->
    </tr>
</thead>
```

### `app/views/account/pages/_page.html.erb`

In `app/views/account/pages/_index.html.erb` you should add a `<td>` as the first cell in the `<tr>`. Be sure to include `data-sortable-target="handle"` on the cell so that the controller recognizes it as a handle.

```html
<tr data-id="<%= page.id %>">
    <td class="cursor-grab" data-sortable-target="handle"><i class="ti ti-menu"></i></td> <!-- Add this line! -->
    <!-- Your existing cells here -->
</tr>
```
