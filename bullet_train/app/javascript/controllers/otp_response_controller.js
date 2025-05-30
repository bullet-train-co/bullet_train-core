import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="otp-response"
export default class extends Controller {
  static values = {
    otpRequired: Boolean,
  };

  connect() {
    document.querySelector("#step-1").classList.add("hidden");
    document.querySelector("#step-2").classList.remove("hidden");
    if (this.otpRequiredValue) {
      document.querySelector("#step-2-otp").classList.remove("hidden");
    }
    setTimeout(function() {
      document.querySelector("#user_password").focus();
      document.querySelector("#new_user").setAttribute('action', '/users/sign_in')
      document.querySelector("#new_user").setAttribute('data-remote', 'false');

      // TODO: Why do we need this? How is the button getting disabled?
      // Does Turbo automatically disable submit buttons in a turbo form when it is submitted?
      document.querySelector("#sign_in_submit").removeAttribute('disabled');
    }, 1);
    this.element.remove();
  }
}
