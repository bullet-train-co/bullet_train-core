import { Controller } from "stimulus";
import zxcvbn from "zxcvbn";

export default class extends Controller {
  static targets = ["strengthIndicator"];

  estimateStrength(e) {
    const result = zxcvbn(e.target.value);

    if (result.feedback) {
      this.strengthIndicatorTarget.innerText = `${result.feedback.warning}.`;
      this.strengthIndicatorTarget.classList.remove("hidden");
    } else {
      this.strengthIndicatorTarget.classList.add("hidden");
    }
  }
}
