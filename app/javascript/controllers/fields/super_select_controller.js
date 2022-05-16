import { Controller } from "@hotwired/stimulus"
require("select2/dist/css/select2.min.css");
import select2 from "select2";

export default class extends Controller {
  static targets = [ "select" ]
  static values = {
    acceptsNew: Boolean,
    enableSearch: Boolean,
    searchUrl: String,
  }
  
  // will be reissued as native dom events name prepended with '$' e.g. '$change', '$select2:closing', etc
  static jQueryEventsToReissue = [ "change", "select2:closing", "select2:close", "select2:opening", "select2:open", "select2:selecting", "select2:select", "select2:unselecting", "select2:unselect", "select2:clearing", "select2:clear" ]
  

  initialize() {
    this.dispatchNativeEvent = this.dispatchNativeEvent.bind(this)
    if (this.isSelect2LoadedOnWindowJquery) {
      select2(window.$)
    }
  }

  get isSelect2LoadedOnWindowJquery() {
    return (window.$ !== undefined && window.$.select2 === undefined)
  }

  connect() {
    if (this.isSelect2LoadedOnWindowJquery) {
      this.initPluginInstance()
    }
  }

  disconnect() {
    this.teardownPluginInstance()
  }

  cleanupBeforeInit() {
    $(this.element).find('.select2-container--default').remove()
  }

  initPluginInstance() {
    let options = {};

    if (!this.enableSearchValue) {
      options.minimumResultsForSearch = -1;
    }

    options.tags = this.acceptsNewValue

    if (this.searchUrlValue) {
      options.ajax = {
        url: this.searchUrlValue,
        dataType: 'json',
        // We enable pagination by default here
        data: function(params) {
          var query = {
            search: params.term,
            page: params.page || 1
          }
          return query
        }
        // Any additional params go here...
      }
    }

    options.templateResult = this.formatState;
    options.templateSelection = this.formatState;
    options.width = 'style';

    this.cleanupBeforeInit() // in case improperly torn down
    this.pluginMainEl = this.selectTarget // required because this.selectTarget is unavailable on disconnect()
    $(this.pluginMainEl).select2(options);

    this.initReissuePluginEventsAsNativeEvents()
  }

  teardownPluginInstance() {
    if (this.pluginMainEl === undefined) { return }

    // ensure there are no orphaned event handlers
    this.teardownPluginEventsAsNativeEvents()
    
    // revert to original markup, remove any event listeners
    $(this.pluginMainEl).select2('destroy');
  }

  initReissuePluginEventsAsNativeEvents() {
    this.constructor.jQueryEventsToReissue.forEach((eventName) => {
      $(this.pluginMainEl).on(eventName, this.dispatchNativeEvent)
    })
  }
  
  teardownPluginEventsAsNativeEvents() {
    this.constructor.jQueryEventsToReissue.forEach((eventName) => {
      $(this.pluginMainEl).off(eventName)
    })
  }
  
  dispatchNativeEvent(event) {
    const nativeEventName = '$' + event.type // e.g. '$change.select2'
    this.element.dispatchEvent(new CustomEvent(nativeEventName, { detail: { event: event }, bubbles: true, cancelable: false }))
  }

  // https://stackoverflow.com/questions/29290389/select2-add-image-icon-to-option-dynamically
  formatState(opt) {
    var imageUrl = $(opt.element).attr('data-image');
    var imageHtml = "";
    if (imageUrl) {
      imageHtml = '<img src="' + imageUrl + '" /> ';
    }
    return $('<span>' + imageHtml + sanitizeHTML(opt.text) + '</span>');
  }
}

// https://portswigger.net/web-security/cross-site-scripting/preventing
function sanitizeHTML(str) {
  return str.replace(/[^\w. ]/gi, function (c) {
    return '&#' + c.charCodeAt(0) + ';';
  });
};
