import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  showSubmenu(event) {
    let menuItemGroup = event.target.parentElement.querySelector('.menu-item-group');
    menuItemGroup.classList.remove('invisible');
  }

  // TODO: Stimulus JS should be able to use `keydown.tab` and `keydown.tab+shift` as actions.
  // https://stimulus.hotwired.dev/reference/actions#keyboardevent-filter
  toggleSubmenu(event) {
    // If we're tabbing backwards away from a menu item header, we hide the group.
    // Else if we're tabbing forward and it's the last item in the submenu, we hide the group.
    if(event.shiftKey && event.key == 'Tab') {
      if(event.target.classList.contains('menu-item-header')) {
        event.target.nextElementSibling.classList.add('invisible');
      }
    } else if (event.key == "Tab") {
      if(event.target.classList.contains('menu-item-link')) {
        let currentMenuItems = event.target.parentElement.getElementsByTagName("a");
        let lastIndex = currentMenuItems.length - 1;
        if(event.target == currentMenuItems[lastIndex]) {
          let parentItemGroup = event.target.parentElement.closest('.menu-item-group');
          parentItemGroup.classList.add('invisible');
        }
      }
    }
  }
}
