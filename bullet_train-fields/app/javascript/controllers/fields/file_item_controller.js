import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "removeFileFlag",
    "downloadFileButton",
    "removeFileButton",
    "fileName"
  ];

  static values = { id: Number }

  removeFile() {
    if (this.hasDownloadFileButtonTarget) {
      this.downloadFileButtonTarget.classList.add("hidden");
    }

    this.removeFileButtonTarget.classList.add("hidden");
    this.fileNameTarget.classList.add("hidden");
    this.removeFileFlagTarget.value = this.idValue;
  }

}
