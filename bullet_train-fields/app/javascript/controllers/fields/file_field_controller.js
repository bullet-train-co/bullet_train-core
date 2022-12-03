import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "fileField",
    "removeFileFlag",
    "downloadFileButton",
    "removeFileButton",
    "selectFileButton",
    "progressBar",
    "progressLabel",
  ];

  connect() {
    // Add upload event listeners
    const initializeListener = document.addEventListener(
      "direct-upload:initialize",
      (event) => {
        this.selectFileButtonTarget.classList.add("hidden");
        this.progressBarTarget.style.width = "0%";
        this.progressBarTarget.setAttribute("aria-valuenow", 0);
        this.progressBarTarget.parentNode.classList.remove("hidden");
        this.progressLabelTarget.innerText = "0%";
      }
    );

    const progressListener = document.addEventListener(
      "direct-upload:progress",
      (event) => {
        const { progress } = event.detail;
        const width = `${progress.toFixed(1)}%`;

        this.progressBarTarget.setAttribute("aria-valuenow", progress);
        this.progressBarTarget.style.width = width;
        this.progressLabelTarget.innerText = width;

        if (progress >= 50 && !this.progressLabelTarget.classList.contains("animate-pulse")) {
          this.progressLabelTarget.classList.add("animate-pulse");
        }
      }
    );

    const errorListener = document.addEventListener(
      "direct-upload:error",
      (event) => {
        event.preventDefault();

        const { error } = event.detail;
        this.progressBarTarget.innerText = error;
      }
    );

    this.uploadListeners = {
      "direct-upload:initialize": initializeListener,
      "direct-upload:progress": progressListener,
      "direct-upload:error": errorListener,
    };
  }

  disconnect() {
    // Teardown event listeners
    for (const event in this.uploadListeners) {
      document.removeEventListener(event, this.uploadListeners[event]);
    }
  }

  uploadFile() {
    this.fileFieldTarget.click();
  }

  removeFile() {
    if (this.hasDownloadFileButtonTarget) {
      this.downloadFileButtonTarget.classList.add("hidden");
    }

    this.removeFileButtonTarget.classList.add("hidden");
    this.removeFileFlagTarget.value = true;
  }

  handleFileSelected() {
    const statusText = this.selectFileButtonTarget.querySelector("span");
    const icon = this.selectFileButtonTarget.querySelector("i");

    if (this.hasDownloadFileButtonTarget) {
      this.downloadFileButtonTarget.remove();
    }

    statusText.innerText = "Select Another File";
    icon.classList.remove("ti-upload");
    icon.classList.add("ti-check");
  }
}
