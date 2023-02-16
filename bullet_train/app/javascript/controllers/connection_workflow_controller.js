import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  disableTeamButton(event) {
    document.body.style.pointerEvents = "none";
  }
}
