# Super Scaffolding with the `--sortable` option

When issuing a `bin/super-scaffold crud` command, you can pass the `--sortable` option like this:

```
# E.g. Pages belong to a Site and are sortable via drag-and-drop:
rails g model Page site:references name:string path:text
bin/super-scaffold crud Page Site,Team name:text_field path:text_area --sortable
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

Since the button won't be part of the `sortable` root element's descendants (all its direct descendants are sortable by default), you'll need to wrap both the `sortable` element and the save button in a new Stimulus controlled ancestor element.

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

On the button, add a `data-action`

```html
<button data-action="sortable-wrapper#saveSortOrder">Save Sort Order</button>
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

Under the hood, the `sortable` Stimulus controller uses the [dragula](https://github.com/bevacqua/dragula) library.

All of the events that `dragula` defines are re-dispatched as native DOM events. The native DOM event name is prefixed with `sortable:`

| dragula event name  | DOM event name       |
|---------------------|----------------------|
| drag                | sortable:drag        |
| dragend             | sortable:dragend     |
| drop                | sortable:drop        |
| cancel              | sortable:cancel      |
| remove              | sortable:remove      |
| shadow              | sortable:shadow      |
| over                | sortable:over        |
| out                 | sortable:out         |
| cloned              | sortable:cloned      |

The original event's listener arguments are passed to the native DOM event as a simple numbered Array under `event.detail.args`. See [dragula's list of events](https://github.com/bevacqua/dragula#drakeon-events) for the listener arguments.

### Example: Asking for Confirmation on the `drop` Event

Let's say we'd like to ask the user to confirm before saving the new sort order:

> Are you sure you want to place DROPPED ITEM before SIBLING ITEM?

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

And on the `sortable` element, catch the `sortable:drop`, `sortable:drag` (for catching when dragging starts) and `save-sort-order` events. Also define it as the `sortable` target for the `confirm-reorder` controller:

```html
<tbody data-controller="sortable"
  data-sortable-save-on-reorder-value="false"
  data-action="sortable:drop->confirm-reorder#requestConfirmation sortable:drag->confirm-reorder#prepareForRevertOnCancel save-sort-order->sortable#saveSortOrder"
  data-confirm-reorder-target="sortable"
  ...
>
```
