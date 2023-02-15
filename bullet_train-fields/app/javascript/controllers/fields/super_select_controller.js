import { Controller } from "@hotwired/stimulus"
require("select2/dist/css/select2.min.css");
import select2 from "select2";

const select2SelectedPreviewSelector = ".select2-selection--single"
const select2SearchInputFieldSelector = ".select2-search__field"

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
    if (!this.isSelect2LoadedOnWindowJquery) {
      select2()
    }
  }

  get isSelect2LoadedOnWindowJquery() {
    return window?.$?.fn?.select2 !== undefined
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
    let options = {
      dropdownParent: $(this.element)
    };

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
  
  open() {
    $(this.pluginMainEl).select2('open')
  }
  
  focusOnTextField(event) {
    this.element.querySelector(select2SearchInputFieldSelector)?.focus()
  }
  
  injectKeystrokeIntoTextField(event) {
    if (!event?.srcElement.matches(select2SelectedPreviewSelector)) { return }
    
    if (["Shift", "Alt", "Control", "Meta", "Tab", "Backspace", "Escape"].includes(event.key)) { return }
    
    this.open()
    
    const searchInputField = this.element.querySelector(select2SearchInputFieldSelector)
    
    if (!searchInputField) { return }
    
    if (event.type !== "keydown") {
      // since keydown precedes keyup, and since keyup is what sends the key to an input field, this next line isn't necessary if keydown is the event captured. We'll just focus on the input field, and the keyup will caught by the input field naturally.
      searchInputField.value = searchInputField.value + event.key
    }
    searchInputField.focus()
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
