import { Controller } from "@hotwired/stimulus";
import zxcvbn from "zxcvbn";

export default class extends Controller {
  static targets = ["strengthIndicator"];

  estimateStrength(e) {
    const result = zxcvbn(e.target.value);

    if (result.feedback && result.feedback.warning.length > 0) {
      this.strengthIndicatorTarget.innerText = `${result.feedback.warning}.`;
      this.strengthIndicatorTarget.classList.remove("hidden");
    } else {
      this.strengthIndicatorTarget.classList.add("hidden");
    }
  }
}
