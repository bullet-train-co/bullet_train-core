import { Controller } from "@hotwired/stimulus"
import { post } from '@rails/request.js'
require("dragula/dist/dragula.min.css")

import dragula from 'dragula';

export default class extends Controller {
  static values = {
    reorderPath: String,
    saveOnReorder: { type: Boolean, default: true }
  }
  
  // will be reissued as native dom events name prepended with 'sortable:' e.g. 'sortable:drag', 'sortable:drop', etc
  static pluginEventsToReissue = [ "drag", "dragend", "drop", "cancel", "remove", "shadow", "over", "out", "cloned" ]

  connect() {
    if (!this.hasReorderPathValue) { return }
    this.initPluginInstance()
  }

  disconnect() {
    this.teardownPluginInstance()
  }

  initPluginInstance() {
    const self = this
    this.plugin = dragula([this.element], {
      moves: function(el, container, handle) {
        var $handles = $(el).find('.reorder-handle')
        if ($handles.length) {
          return !!$(handle).closest('.reorder-handle').length
        } else {
          if (!$(handle).closest('.undraggable').length) {
            return self.element === container
          } else {
            return false
          }
        }
      },
      accepts: function (el, target, source, sibling) {
        if ($(sibling).hasClass('undraggable') && $(sibling).prev().hasClass('undraggable')) {
          return false
        } else {
          return true
        }
      },
    }).on('drop', function (el) {
      // save order here.
      if (self.saveOnReorderValue) {
        self.saveSortOrder()
      }
    }).on('over', function (el, container) {
      // deselect any text fields, or else things go slow!
      $(document.activeElement).blur()
    })
    
    this.initReissuePluginEventsAsNativeEvents()
  }
  
  initReissuePluginEventsAsNativeEvents() {
    this.constructor.pluginEventsToReissue.forEach((eventName) => {
      this.plugin.on(eventName, (...args) => {
        this.dispatch(eventName, { detail: { plugin: 'dragula', type: eventName, args: args }})
      })
    })
  }

  teardownPluginInstance() {
    if (this.plugin === undefined) { return }

    // revert to original markup, remove any event listeners
    this.plugin.destroy()
  }
  
  saveSortOrder() {
    var idsInOrder = Array.from(this.element.childNodes).map((el) => { return parseInt(el.dataset?.id) });
    
    post(this.reorderPathValue, { body: JSON.stringify({ids_in_order: idsInOrder}) })
  }

}