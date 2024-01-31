import { Controller } from "@hotwired/stimulus"
import '@simonwep/pickr/dist/themes/monolith.min.css'

import Pickr from '@simonwep/pickr'

const generatedPickerHexInputSelector = 'input.pcr-result'

export default class extends Controller {
  static targets = [
    'colorPickerValue',
    'colorField',
    'colorInput',
    'userSelectedColor',
    'colorOptions',
    'pickerContainer',
    'togglePickerButton',
    'colorButton',
  ]
  static values = { initialColor: String }
  static classes = ['colorSelected']

  connect() {
    this.initPluginInstance()
  }

  disconnect() {
    this.teardownPluginInstance()
  }



  pickColor(event) {
    event.preventDefault()

    const targetEl = event.target
    const color = targetEl.dataset.color

    this.colorInputTarget.value = color
    this.colorPickerValueTarget.value = color
    this.userSelectedColorTarget.dataset.color = color

    this.pickr.setColor(color)
  }

  pickRandomColor(event) {
    event.preventDefault()

    const r = Math.floor(Math.random() * 256)
    const g = Math.floor(Math.random() * 256)
    const b = Math.floor(Math.random() * 256)

    this.pickr.setColor(`rgb ${r} ${g} ${b}`)
    const hexColor = this.pickr.getColor().toHEXA().toString()
    this.pickr.setColor(hexColor)

    this.showUserSelectedColor(hexColor)
  }

  showUserSelectedColor(color) {
    this.colorInputTarget.value = color
    this.colorPickerValueTarget.value = color

    this.userSelectedColorTarget.style.backgroundColor = color
    this.userSelectedColorTarget.style.setProperty('--tw-ring-color', color)
    this.userSelectedColorTarget.setAttribute('data-color', color)
    this.userSelectedColorTarget.classList.remove('hidden')
  }

  unpickColor(event) {
    event.preventDefault()
    this.colorPickerValueTarget.value = ''
    this.colorInputTarget.value = ''
    this.userSelectedColorTarget.classList.add('hidden')
    this.dispatchChangeEvent()
  }

  dispatchChangeEvent() {
    this.colorInputTarget.dispatchEvent(new Event('change'))
  }

  highlightColorButtonsMatchingSelectedColor() {
    this.colorButtonTargets.forEach((button) => {
      const buttonColor = button.dataset?.color
      if (this.selectedColor !== undefined && buttonColor.toLowerCase() === this.selectedColor.toLowerCase()) {
        button.classList.add(...this.colorSelectedClasses)
      } else {
        button.classList.remove(...this.colorSelectedClasses)
      }
    })
  }

  togglePickr(event) {
    event.preventDefault()
  }

  initPluginInstance() {
    this.pickr = Pickr.create({
      el: this.togglePickerButtonTarget,
      container: this.pickerContainerTarget,
      theme: 'monolith',
      useAsButton: true,
      default: this.initialColorValue || '#1E90FF',
      components: {
        // Main components
        preview: true,
        hue: true,

        // Input / output Options
        interaction: {
          input: true,
          save: true,
        },
      },
    })

    this.pickr.on('save', (color, _instance) => {
      const hexaColor = color.toHEXA().toString().toLowerCase()
      if (!this.colorOptions.includes(hexaColor)) {
        this.showUserSelectedColor(hexaColor)
      }
      this.dispatchChangeEvent()
      this.highlightColorButtonsMatchingSelectedColor()
      this.pickr.hide()
    })
  }

  handleKeydown(event) {
    if (!event.target.matches(generatedPickerHexInputSelector)) {
      return
    }
    if (event.key !== 'Enter') {
      return
    }

    event.preventDefault()
    event.stopPropagation()
    this.pickr.applyColor(false)
  }

  teardownPluginInstance() {
    this.pickr.destroy()
  }

  get colorOptions () {
    const colorButtons = this.colorOptionsTarget.querySelectorAll('button[data-color]')
    return Array.prototype.slice.call(colorButtons).map((el) => { return el.dataset.color })
  }

  get selectedColor() {
    return this.colorInputTarget.value
  }
}
