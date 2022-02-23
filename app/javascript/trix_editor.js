import Tribute from 'tributejs'
require("trix/dist/trix.css");

require("trix")
require("@rails/actiontext")

// only show the editor tool bar when the user is editing the field.
// inspired by https://github.com/basecamp/trix/issues/343 and `app/assets/stylesheets/account/fields/trix_editor.scss`

export function trixEditor() {
  document.addEventListener('trix-initialize', function() {
    addEventListener("trix-focus", updateTrixToolbarVisability);
    addEventListener("trix-blur", updateTrixToolbarVisability);
    updateTrixToolbarVisability();
    initializeTribute();
  })
}

function updateTrixToolbarVisability() {
  document.querySelectorAll("trix-editor").forEach((editorElement, index) => {
    var toolbarElement = editorElement.toolbarElement;
    if (editorElement == document.activeElement) {
      toolbarElement.classList.add('visible');
    } else {
      // don't hide the toolbar if we've unfocused to focus on the link dialog.
      if (!toolbarElement.contains(document.activeElement)) {
        toolbarElement.classList.remove('visible');
      }
    }
  })
}

function initializeTribute() {
  document.querySelectorAll("trix-editor").forEach((el, index) => {
    var editor = el.editor;
    
    var mentionConfig = {
      trigger: '@',
      values: JSON.parse(editor.element.dataset.mentions),
      selectTemplate: function (item) {
        item = item.original;
        return '<a href="' + item.protocol + '://' + item.model + '/' + item.id + '">' + item.label + '</a>';
      },
      menuItemTemplate: function (item) {
        return '<img src="' + item.original.photo + '" /> ' + item.string;
      },
      requireLeadingSpace: true,
      replaceTextSuffix: ''
    }
  
    var topicConfig = {
      trigger: '#',
      values: JSON.parse(editor.element.dataset.topics),
      selectTemplate: function (item) {
        item = item.original;
        return '<a href="' + item.protocol + '://' + item.model + '/' + item.id + '">' + item.label + '</a>';
      },
      menuItemTemplate: function (item) {
        return '<img src="' + item.original.photo + '" /> ' + item.string;
      },
      requireLeadingSpace: true,
      replaceTextSuffix: ''
    }
  
    var tribute = new Tribute({
      collection: [topicConfig, mentionConfig],
    });
  
    tribute.attach(el);
  })
}
