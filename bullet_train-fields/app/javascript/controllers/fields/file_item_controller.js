import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "removeFileFlag",
    "downloadFileButton",
    "removeFileButton",
    "cancelRemoveFileButton",
    "fileName"
  ];

  static values = { id: Number }

  removeFile() {
    if (this.hasDownloadFileButtonTarget) {
      this.downloadFileButtonTarget.classList.add("hidden");
    }

    this.removeFileButtonTarget.classList.add("hidden");
    this.cancelRemoveFileButtonTarget.classList.remove("hidden");
    this.removeFileFlagTarget.value = this.idValue;
    this.element.classList.add("bg-red-100", "dark:bg-red-700");
  }

  cancelRemoveFile(){
    if (this.hasDownloadFileButtonTarget) {
      this.downloadFileButtonTarget.classList.remove("hidden");
    }

    this.removeFileButtonTarget.classList.remove("hidden");
    this.cancelRemoveFileButtonTarget.classList.add("hidden");
    this.removeFileFlagTarget.value = null;
    this.element.classList.remove("bg-red-100", "dark:bg-red-700");
  }

}
