import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [ "menuItemHeader", "menuItemGroup", "menuItemLink" ];

  showSubmenu() {
    this.menuItemGroupTarget.classList.remove('invisible');
  }

  // TODO: Stimulus JS should be able to use `keydown.tab` and `keydown.tab+shift` as actions.
  // https://stimulus.hotwired.dev/reference/actions#keyboardevent-filter
  hideSubmenu(event) {
    let hideMenu = false;

    // If we're tabbing forward and go outside of the submenu, we hide the group.
    // Else if we're tabbing backwards and go outside via the menu item header, we hide the group.
    if(event.key == 'Tab' && !event.shiftKey) {
      let lastIndex = this.menuItemLinkTargets.length - 1;
      hideMenu = event.target == this.menuItemLinkTargets[lastIndex]
    } else if (event.key == 'Tab' && event.shiftKey) {
      hideMenu = event.target == this.menuItemHeaderTarget
    }

    if(hideMenu) { this.menuItemGroupTarget.classList.add('invisible'); }
  }
}
