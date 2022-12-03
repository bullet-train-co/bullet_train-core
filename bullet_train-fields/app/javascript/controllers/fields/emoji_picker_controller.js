import { Controller } from "@hotwired/stimulus"
import { Picker } from 'emoji-mart'


export default class extends Controller {

  static targets = [ "input", "display" ]

  connect() {
    this.visible = false
    this.picker = new Picker({
      data: async () => {
        const response = await fetch(
          'https://cdn.jsdelivr.net/npm/@emoji-mart/data',
        )

        return response.json()
      },
      onEmojiSelect: (emoji) => {
        this.displayTarget.innerHTML = emoji.native
        this.inputTarget.value = emoji.native
        this.element.removeChild(this.picker)
        this.visible = false
      },

    })
  }

  toggle(event) {
    event.preventDefault()
    if (this.visible) {
      this.element.removeChild(this.picker)
    } else {
      this.element.appendChild(this.picker)
    }
    this.visible = !this.visible
  }
}
