# Super Scaffolding with the `--sortable` option

<div class="rounded-md border bg-amber-100 border-amber-200 py-4 px-5 mb-3 not-prose">
  <h3 class="text-sm text-amber-800 font-light mb-2">
    Note: These docs are for the old sortable controller based on `dragula`.
  </h3>
  <p class="text-sm text-amber-800 font-light">
    <a href="/docs/super-scaffolding/sortable">You can find the new documentation here.</a>
  </p>
</div>

## Continuing to use the `dragula` based sortable controller

We no longer include the old `dragula` controller in the NPM package for `bullet_train-sortable` because doing so would require `dragula` to still be a hard dependency.

If you want to continue using that controller you'll need to do a few things.

### 1. Add `dragula` and `jquery` as dependencies in your package.json

Since we don't include `dragula` and `jquery` as dependencies anymore you need to include them in your own `package.json`.

```
yarn add dragula jquery
```

### 2. Copy `dragula-sortable_controller.js` into your project

You can grab the old controller [from the `core` repo here](https://github.com/bullet-train-co/bullet_train-core/blob/main/bullet_train-sortable/app/javascript/controllers/dragula-sortable_controller.js).

You should put it in your app at `app/javascript/controllers/dragule-sortable_controller.js`

### 3. Update references to the sortable controller to use `dragula-sortable`

Assuming you have a sortable `Page` model the file you need to update is `app/views/account/pages/_index.html.erb`.

On the `<tbody>` you need to change `data-controller="sortable"` to be `data-controller="dragula-sortable"`.

If you're responding to any of the events emitted by the controller they will also need to be changed from `sortable` to `dragula-sortable`.

## Old docs

The remainder of this page is the original documentation for the dragula based sortable controller. It has been updated with the assumption that your dragula based Stimulus controller will be in the file `dragula-sortable_controller.js`.

---

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

Add the  `data-dragula-sortable-save-on-reorder-value="false"` param on the `dragula-sortable` root element:

```html
<tbody data-controller="dragula-sortable"
  data-dragula-sortable-save-on-reorder-value="false"
  ...
>
```

### To manually fire the save action via a button

Since the button won't be part of the `dragula-sortable` root element's descendants (all its direct descendants are sortable by default), you'll need to wrap both the `dragula-sortable` element and the save button in a new Stimulus controlled ancestor element. On the button, add a `data-action`.

For instance:

```html
<div data-controller="dragula-sortable-wrapper">
    <table>...</table>
    <button data-action="dragula-sortable-wrapper#saveSortOrder">Save Sort Order</button>
</div>
```

```js
/* dragula-sortable-wrapper_controller.js */
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "dragula-sortable" ]

  saveSortOrder() {
    if (!this.hasSortableTarget) { return }
    this.sortableTarget.dispatchEvent(new CustomEvent("save-sort-order"))
  }
}
```

And on the `dragula-sortable` element, catch the `save-sort-order` event and define it as the `dragula-sortable` target for the `dragula-sortable-wrapper` controller:

```html
<tbody data-controller="dragula-sortable"
  data-dragula-sortable-save-on-reorder-value="false"
  data-action="save-sort-order->dragula-sortable#saveSortOrder"
  data-dragula-sortable-wrapper-target="dragula-sortable"
  ...
>
```

## Events

Under the hood, the `dragula-sortable` Stimulus controller uses the [dragula](https://github.com/bevacqua/dragula) library.

All of the events that `dragula` defines are re-dispatched as native DOM events. The native DOM event name is prefixed with `dragula-sortable:`

| dragula event name  | DOM event name               |
|---------------------|------------------------------|
| drag                | dragula-sortable:drag        |
| dragend             | dragula-sortable:dragend     |
| drop                | dragula-sortable:drop        |
| cancel              | dragula-sortable:cancel      |
| remove              | dragula-sortable:remove      |
| shadow              | dragula-sortable:shadow      |
| over                | dragula-sortable:over        |
| out                 | dragula-sortable:out         |
| cloned              | dragula-sortable:cloned      |

The original event's listener arguments are passed to the native DOM event as a simple numbered Array under `event.detail.args`. See [dragula's list of events](https://github.com/bevacqua/dragula#drakeon-events) for the listener arguments.

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
  static targets = [ "dragula-sortable" ]

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

And on the `dragula-sortable` element, catch the `dragula-sortable:drop`, `dragula-sortable:drag` (for catching when dragging starts) and `save-sort-order` events. Also define it as the `dragula-sortable` target for the `confirm-reorder` controller:

```html
<tbody data-controller="dragula-sortable"
  data-dragula-sortable-save-on-reorder-value="false"
  data-action="dragula-sortable:drop->confirm-reorder#requestConfirmation dragula-sortable:drag->confirm-reorder#prepareForRevertOnCancel save-sort-order->dragula-sortable#saveSortOrder"
  data-confirm-reorder-target="dragula-sortable"
  ...
>
```
