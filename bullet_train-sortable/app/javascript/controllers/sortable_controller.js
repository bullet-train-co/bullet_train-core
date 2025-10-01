import { Controller } from "@hotwired/stimulus"
import { post } from '@rails/request.js'

// Connects to data-controller="sortable"
export default class extends Controller {
  static values = {
    reorderPath: String,
    saveOnReorder: { type: Boolean, default: true }
  }
  static classes = ["activeDropzone", "activeItem", "dropTarget"];
  static targets = [ "handle"];

  async saveSortOrder(idsInOrder) {
    await post(this.reorderPathValue, { body: JSON.stringify({ids_in_order: idsInOrder}) })
  }

  connect() {
    const saveOrderCallback = this.saveOnReorderValue ? this.saveSortOrder.bind(this) : null;
    this.sortingPlugin = new SortableTable(
      this.element,
      saveOrderCallback,
      this.handleTargets,
      {
        activeDropzoneClasses: this.activeDropzoneClasses,
        activeItemClasses: this.activeItemClasses,
        dropTargetClasses: this.dropTargetClasses
      }
    );
  }

  disconnect() {
    this.sortingPlugin.destroy();
  }
}

function getDataNode(node) {
  return node.closest("[data-id]");
}

function getHandleNode(node) {
  return node.closest("[data-sortable-target='handle']");
}

function getMetaValue(name) {
  const element = document.head.querySelector(`meta[name="${name}"]`);
  return element.getAttribute("content");
}

class SortableTable{
  // We'll emit events using this prefix. `sortable:drag` & `sortable:drop` for instance.
  static eventPrefix = "sortable";
  // These are defaults so that we don't have to require people to update their templates.
  // If the template does contain values for any of these the template values will be used instead.
  static defaultClasses = {
    "activeDropzoneClasses": "border-dashed bg-gray-50 border-slate-400",
    "activeItemClasses": "shadow bg-white cursor-grabbing bg-white *:bg-white opacity-100 *:opacity-100",
    "dropTargetClasses": "shadow-inner shadow-gray-500 hover:shadow-inner bg-gray-100 *:opacity-0 *:bg-gray-100"
  };

  constructor(tbodyElement, saveSortOrder, handleTargets, styles, customEventPrefix){
    this.element = tbodyElement;
    this.saveSortOrder = saveSortOrder;
    this.handleTargets = handleTargets;

    this.activeDropzoneClassesWithDefaults = styles.activeDropzoneClasses.length == 0 ? this.constructor.defaultClasses["activeDropzoneClasses"].split(" ") : styles.activeDropzoneClasses;
    this.activeItemClassesWithDefaults = styles.activeItemClasses.length == 0 ? this.constructor.defaultClasses["activeItemClasses"].split(" ") : styles.activeItemClasses;
    this.dropTargetClassesWithDefaults = styles.dropTargetClasses.length == 0 ? this.constructor.defaultClasses["dropTargetClasses"].split(" ") : styles.dropTargetClasses;
    this.eventPrefixWithDefaults = customEventPrefix ? customEventPrefix : this.constructor.eventPrefix;

    this.element.addEventListener('dragstart', this.dragstart.bind(this));
    this.element.addEventListener('dragover', this.dragover.bind(this));
    this.element.addEventListener('dragenter', this.dragenter.bind(this));
    this.element.addEventListener('dragleave', this.dragleave.bind(this));
    this.element.addEventListener('dragend', this.dragend.bind(this));
    this.element.addEventListener('drop', this.drop.bind(this));

    if(this.handleTargets.length == 0){
      this.addDragHandles();
    }

    this.element.addEventListener('mousedown', this.dragHandleMouseDown.bind(this));
    this.element.addEventListener('mouseup', this.dragHandleMouseUp.bind(this));

    // We set this when we've detected `mousedown` in a handle. Then all of the `drag*` handlers
    // bail out if we don't have a draggable row. This prevents problems and weird behavior if you
    // drag something other than the handle. Like highlighted text, or a link, for instance.
    this.aRowIsDraggable = false;
  }

  destroy(){
    this.element.removeEventListener('dragstart', this.dragstart.bind(this));
    this.element.removeEventListener('dragover', this.dragover.bind(this));
    this.element.removeEventListener('dragenter', this.dragenter.bind(this));
    this.element.removeEventListener('dragleave', this.dragleave.bind(this));
    this.element.removeEventListener('dragend', this.dragend.bind(this));
    this.element.removeEventListener('drop', this.drop.bind(this));

    this.element.removeEventListener('mousedown', this.dragHandleMouseDown.bind(this));
    this.element.removeEventListener('mouseup', this.dragHandleMouseUp.bind(this));
  }

  dragHandleMouseDown(event){
    const handle = getHandleNode(event.target);
    if(!handle){
      return;
    }
    const draggableItem = getDataNode(event.target);
    if(draggableItem){
      draggableItem.setAttribute('draggable', true);
      this.aRowIsDraggable = true;
    }
  }

  dragHandleMouseUp(event){
    const handle = getHandleNode(event.target);
    if(!handle){
      return;
    }
    const draggableItem = getDataNode(event.target);
    if(draggableItem){
      draggableItem.setAttribute('draggable', false);
      this.aRowIsDraggable = false;
    }
  }

  dragstart(event) {
    if(!this.aRowIsDraggable){
      return;
    }
    this.element.classList.add(...this.activeDropzoneClassesWithDefaults);
    const draggableItem = getDataNode(event.target);
    draggableItem.classList.add(...this.activeItemClassesWithDefaults);
    event.dataTransfer.setData(
      "application/drag-key",
      draggableItem.dataset.id
    );
    event.dataTransfer.effectAllowed = "move";
    // For most browsers we could rely on the dataTransfer.setData call above,
    // but Safari doesn't seem to allow us access to that data at any time other
    // than during a drop. But we need it during dragenter to reorder the list
    // as the drag happens. So, we just stash the value here and then use it later.
    this.draggingDataId = draggableItem.dataset.id;

    this.dispatch('start', { detail: { type: 'start', args: [draggableItem, this.element] }})
    // We're dispatching drag here in addition to start to retain backwards compatibility with dragula.js.
    // It emits a single 'drag' event when an item is first dragged, but not on each movement thereafter.
    this.dispatch('drag', { detail: { type: 'drag', args: [draggableItem, this.element] }})
  }

  dragover(event) {
    if(!this.aRowIsDraggable){
      return;
    }
    event.preventDefault();
    return true;
  }

  dragenter(event) {
    if(!this.aRowIsDraggable){
      return;
    }
    let parent = getDataNode(event.target);

    // We keep a count of the `dragenter` events for the row being dragged to fix jank. When dragging between cells
    // (or cell content) within a row a dragenter event is fired before the dragleave event from the previous cell.
    // If we removed the activeItemClasses when the dragleave happens then the UI doesn't match expectations.
    if(parent.dataset.dragEnterCount){
      parent.dataset.dragEnterCount = parseInt(parent.dataset.dragEnterCount) + 1;
    }else{
      parent.dataset.dragEnterCount = 1;
    }

    if (parent != null && parent.dataset.id != null) {
      parent.classList.add(...this.dropTargetClassesWithDefaults);
      var data = this.draggingDataId;
      const draggedItem = this.element.querySelector(
        `[data-id='${data}']`
      );

      if (draggedItem) {
        draggedItem.classList.remove(...this.activeItemClassesWithDefaults);

        let dispatchEvent = false;

        if (parent.compareDocumentPosition(draggedItem) & Node.DOCUMENT_POSITION_FOLLOWING) {
          let result = parent.insertAdjacentElement( "beforebegin", draggedItem);
          dispatchEvent = true;
        } else if (parent.compareDocumentPosition(draggedItem) & Node.DOCUMENT_POSITION_PRECEDING) {
          let result = parent.insertAdjacentElement("afterend", draggedItem);
          dispatchEvent = true;
        }

        if(dispatchEvent){
          this.dispatch('reordered', { detail: { type: 'shadow', args: [draggedItem, this.element, this.element] }});
          // We're dispatching 'shadow' here to retain backwards compatibility with dragula.js.
          // It emits a 'shadow' event when the items in the list are rearranged mid-drag.
          // TODO: This is firing more often than dragula fires it. Is that a problem?
          this.dispatch('shadow', { detail: { type: 'shadow', args: [draggedItem, this.element, this.element] }});
        }

      }
      event.preventDefault();
    }
  }

  dragleave(event) {
    if(!this.aRowIsDraggable){
      return;
    }
    let parent = getDataNode(event.target);

    if(parent.dataset.dragEnterCount > 0){
      parent.dataset.dragEnterCount = parseInt(parent.dataset.dragEnterCount) - 1;
    }

    if (parent != null && parent.dataset.id != null && parent.dataset.dragEnterCount == 0) {
      parent.classList.remove(...this.dropTargetClassesWithDefaults);
      event.preventDefault();
    }
  }

  async drop(event) {
    if(!this.aRowIsDraggable){
      return;
    }
    this.element.classList.remove(...this.activeDropzoneClassesWithDefaults);

    const dropTarget = getDataNode(event.target);
    dropTarget.classList.remove(...this.dropTargetClassesWithDefaults);

    var data = this.draggingDataId;
    const draggedItem = this.element.querySelector(
      `[data-id='${data}']`
    );

    if (draggedItem) {
      draggedItem.classList.remove(...this.activeItemClassesWithDefaults);

      if (
        dropTarget.compareDocumentPosition(draggedItem) &
        Node.DOCUMENT_POSITION_FOLLOWING
      ) {
        let result = dropTarget.insertAdjacentElement(
          "beforebegin",
          draggedItem
        );
      } else if (
        dropTarget.compareDocumentPosition(draggedItem) &
        Node.DOCUMENT_POSITION_PRECEDING
      ) {
        let result = dropTarget.insertAdjacentElement("afterend", draggedItem);
      }

      if (this.saveSortOrder) {
        var idsInOrder = Array.from(this.element.childNodes).map((el) => { return el.dataset?.id ? parseInt(el.dataset?.id) : null });
        idsInOrder = idsInOrder.filter(element => element !== null);
        await this.saveSortOrder(idsInOrder);
        this.dispatch('saved', { detail: { type: 'saved', args: [this.element] }})
      }

      // TODO: This fires more often than dragula fires it. Dragula does not fire this when an item was dragged but not moved/reorded.
      // Instead dragula fires a `cancel` event. But we're firing a `drop` and no `cancel` in that situation.
      this.dispatch('drop', { detail: { type: 'drop', args: [draggedItem, this.element, this.element, draggedItem.nextElementSibling] }})
    }
    event.preventDefault();
  }

  dragend(event) {
    if(!this.aRowIsDraggable){
      return;
    }
    this.element.classList.remove(...this.activeDropzoneClassesWithDefaults);

    const draggableItem = getDataNode(event.target);
    draggableItem.setAttribute('draggable', false);
    draggableItem.dataset.dragEnterCount = 0;

    this.dispatch('end', { detail: { type: 'end', args: [draggableItem, this.element] }})
    // We emit dragend here as well to maintain some backwards compatiblity with the old dragula controller.
    this.dispatch('dragend', { detail: { type: 'dragend', args: [draggableItem, this.element] }})
  }

  addDragHandles(){
    // Here we assume that this controller is connected to a tbody element
    const table = this.element.parentNode;
    const thead = table.querySelector('thead');
    const headRow = thead.querySelector('tr');
    const newTh = document.createElement('th');
    newTh.classList.add(...'w-6'.split(' '))
    headRow.prepend(newTh);

    const draggables = this.element.querySelectorAll('tr');
    for (const draggable of draggables) {
      const newCell = document.createElement('td');
      newCell.dataset.sortableTarget = 'handle';
      newCell.classList.add(...'cursor-grab'.split(' '));

      const icon = document.createElement('i');
      icon.classList.add(...'ti ti-menu invisible group-hover:visible'.split(' '));

      newCell.append(icon);
      draggable.prepend(newCell);
      this.handleTargets.push(newCell);
    }
  }

  dispatch(eventName,data){
    const fullEventName = this.eventPrefixWithDefaults + ":" + eventName;
    const event = new CustomEvent(fullEventName, data);
    this.element.dispatchEvent(event);
  }

  // TODO: I'm not sure this is adequate. I think we may need to "manually" dispatch these from within the
  // approriate event handles so that we can add more info to `args`. For instance, the "drop" event may
  // need to include the sibling that the dropped element was dropped in front of. Related, do people actually
  // use these re-issued events?
  /*
  initReissuePluginEventsAsNativeEvents() {
    this.constructor.pluginEventsToReissue.forEach((eventName) => {
      this.element.addEventListener(eventName, (...args) => {
        this.dispatch(eventName, { detail: { type: eventName, args: args }})
      })
    })
  }
  */

}
