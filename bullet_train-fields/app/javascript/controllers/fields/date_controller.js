import { Controller } from "@hotwired/stimulus"
require("daterangepicker/daterangepicker.css");

// requires jQuery, moment, might want to consider a vanilla JS alternative
import jquery from "jquery";
import 'daterangepicker';
import moment from 'moment-timezone'
import select2 from "select2";

export default class extends Controller {
  static targets = [ "field", "displayField", "clearButton", "currentTimeZoneWrapper", "timeZoneButtons", "timeZoneSelectWrapper", "timeZoneField", "timeZoneSelect" ]
  static values = {
    includeTime: Boolean,
    defaultTimeZones: Array,
    dateFormat: String,
    timeFormat: String,
    currentTimeZone: String,
    isAmPm: Boolean,
    pickerLocale: { type: Object, default: {} }
  }

  initialize() {
    if (window.jQuery === undefined) {
      window.jQuery = jquery // required for select2 used for time zone select, but we also use global jQuery throughout below
    }
    if (!this.isSelect2LoadedOnWindowJquery) {
      select2()
    }
  }

  get isSelect2LoadedOnWindowJquery() {
    return window?.jQuery?.fn?.select2 !== undefined
  }

  connect() {
    this.initPluginInstance()
  }

  disconnect() {
    this.teardownPluginInstance()
  }

  clearDate(event) {
    // don't submit the form, unless it originated from the cancel/clear button
    event.preventDefault()

    this.fieldTarget.value = ''
    this.displayFieldTarget.value = ''
  }

  currentTimeZone(){
    return (
      ( this.hasTimeZoneSelectWrapperTarget && jQuery(this.timeZoneSelectWrapperTarget).is(":visible") && this.timeZoneSelectTarget.value ) ||
      ( this.hasTimeZoneFieldTarget && this.timeZoneFieldTarget.value ) ||
        this.currentTimeZoneValue
    )
  }

  applyDateToField(event, picker) {
    const format = this.includeTimeValue ? this.timeFormatValue : this.dateFormatValue
    const newTimeZone = this.currentTimeZone()
    const momentVal = (
      picker ?
      moment(picker.startDate.toISOString()).tz(newTimeZone, true) :
      moment.tz(moment(this.fieldTarget.value, "YYYY-MM-DDTHH:mm").format("YYYY-MM-DDTHH:mm"), newTimeZone) 
    )
    const displayVal = momentVal.format(format)
    const dataVal = this.includeTimeValue ? momentVal.toISOString(true) : momentVal.format('YYYY-MM-DD')
    this.displayFieldTarget.value = displayVal
    this.fieldTarget.value = dataVal
    // bubble up a change event when the input is updated for other listeners
    if(picker){
      this.displayFieldTarget.dispatchEvent(new CustomEvent('change', { detail: { picker: picker }}))
    }
  }

  showTimeZoneButtons(event) {
    // don't follow the anchor
    event.preventDefault()

    this.currentTimeZoneWrapperTarget.classList.toggle('hidden')
    this.timeZoneButtonsTarget.classList.toggle('hidden')
  }

  // triggered on other click from the timezone buttons
  showTimeZoneSelectWrapper(event) {
    // don't follow the anchor
    event.preventDefault()

    this.timeZoneButtonsTarget.classList.toggle('hidden')
    if (this.hasTimeZoneSelectWrapperTarget) {
      this.timeZoneSelectWrapperTarget.classList.toggle('hidden')
    }
    if(!["", null].includes(this.fieldTarget.value)){
      jQuery(this.displayFieldTarget).trigger("apply.daterangepicker");
    }
  }

  resetTimeZoneUI(e) {
    e && e.preventDefault()

    this.currentTimeZoneWrapperTarget.classList.remove('hidden')
    this.timeZoneButtonsTarget.classList.add('hidden')

    if (this.hasTimeZoneSelectWrapperTarget) {
      this.timeZoneSelectWrapperTarget.classList.add('hidden')
    }
  }

  // triggered on selecting a new timezone using the buttons
  setTimeZone(event) {
    // don't follow the anchor
    event.preventDefault()
    const currentTimeZoneEl = this.currentTimeZoneWrapperTarget.querySelector('a')
    if (this.hasTimeZoneFieldTarget) {
      this.timeZoneFieldTarget.value = event.target.dataset.value
    }
    currentTimeZoneEl.textContent = event.target.dataset.label
    this.element.querySelectorAll('.time-zone-button').forEach(el => {
      el.classList.remove('button');
      el.classList.add('button-alternative');
    });
    event.target.classList.remove('button-alternative')
    event.target.classList.add('button')
    this.resetTimeZoneUI()
    if(!["", null].includes(this.fieldTarget.value)){
      jQuery(this.displayFieldTarget).trigger("apply.daterangepicker");
    }
  }

  // triggered on selecting a new timezone from the timezone picker
  selectTimeZoneChange(event) {
    if(!["", null].includes(this.fieldTarget.value)){
      jQuery(this.displayFieldTarget).trigger("apply.daterangepicker");
    }
  }

  // triggered on cancel click from the timezone picker
  cancelSelect(event) {
    event.preventDefault()
    this.resetTimeZoneUI()
    if(!["", null].includes(this.fieldTarget.value)){
      jQuery(this.displayFieldTarget).trigger("apply.daterangepicker")
    }
  }

  displayFieldChange(event) {
    const newTimeZone = this.currentTimeZone()
    const format = this.includeTimeValue ? this.timeFormatValue : this.dateFormatValue
    const momentParsed = moment(this.displayFieldTarget.value, format, false)
    if(momentParsed.isValid()){
      const momentVal = moment.tz(momentParsed.format("YYYY-MM-DDTHH:mm"), newTimeZone)
      const dataVal = this.includeTimeValue ? momentVal.toISOString(true) : momentVal.format('YYYY-MM-DD')
      this.fieldTarget.value = dataVal
    } else {
      // nullify field value when the display format is wrong
      this.fieldTarget.value = ''
    }
  }

  initPluginInstance() {
    const localeValues = this.pickerLocaleValue
    const isAmPm = this.isAmPmValue
    localeValues['format'] = this.includeTimeValue ? this.timeFormatValue : this.dateFormatValue

    jQuery(this.displayFieldTarget).daterangepicker({
      singleDatePicker: true,
      timePicker: this.includeTimeValue,
      timePickerIncrement: 5,
      autoUpdateInput: false,
      locale: localeValues,
      timePicker24Hour: !isAmPm,
    })

    jQuery(this.displayFieldTarget).on('apply.daterangepicker', this.applyDateToField.bind(this))
    jQuery(this.displayFieldTarget).on('cancel.daterangepicker', this.clearDate.bind(this))
    jQuery(this.displayFieldTarget).on('input', this,this.displayFieldChange.bind(this));

    this.pluginMainEl = this.displayFieldTarget
    this.plugin = jQuery(this.pluginMainEl).data('daterangepicker') // weird

    // Init time zone select
    if (this.includeTimeValue && this.hasTimeZoneSelectWrapperTarget) {
      this.timeZoneSelect = this.timeZoneSelectWrapperTarget.querySelector('select.select2')

      jQuery(this.timeZoneSelect).select2({
        width: 'style'
      })

      const self = this

      jQuery(this.timeZoneSelect).on('change.select2', function(event) {
        const currentTimeZoneEl = self.currentTimeZoneWrapperTarget.querySelector('a')
        const {value} = event.target

        const selectedTimeZoneOption = event.target.options[event.target.options.selectedIndex]

        if (self.hasTimeZoneFieldTarget) {
          self.timeZoneFieldTarget.value = value
        }
        currentTimeZoneEl.textContent = selectedTimeZoneOption.textContent

        const selectedOptionTimeZoneButton = self.element.querySelector('.selected-option-time-zone-button')

        if (self.defaultTimeZonesValue.includes(selectedTimeZoneOption.textContent)) {
          self.element.querySelectorAll('.time-zone-button').forEach(el => {
            el.classList.remove('button');
            el.classList.add('button-alternative');
          })
          selectedOptionTimeZoneButton.classList.add('hidden')
          selectedOptionTimeZoneButton.hidden = true
          self.element.querySelectorAll(`a[data-value="${value}"`).forEach(el => {
            el.classList.remove('button-alternative')
            el.classList.add('button')
          })
        } else {
          // deselect any selected button
          self.element.querySelectorAll('.time-zone-button').forEach(el => {
            el.classList.remove('button');
            el.classList.add('button-alternative');
          })
          selectedOptionTimeZoneButton.textContent = selectedTimeZoneOption.textContent
          selectedOptionTimeZoneButton.setAttribute('data-value', value)
          selectedOptionTimeZoneButton.hidden = false
          selectedOptionTimeZoneButton.classList.remove('hidden')
          selectedOptionTimeZoneButton.classList.remove('button-alternative')
          selectedOptionTimeZoneButton.classList.add('button')
        }

        self.resetTimeZoneUI()
      })
    }
  }

  teardownPluginInstance() {
    if (this.plugin === undefined) { return }
    jQuery(this.pluginMainEl).off('apply.daterangepicker')
    jQuery(this.pluginMainEl).off('cancel.daterangepicker')
    // revert to original markup, remove any event listeners
    this.plugin.remove()

    if (this.includeTimeValue && this.hasTimeZoneSelectWrapperTarget) {
      jQuery(this.timeZoneSelectTarget).select2('destroy');
    }
  }
}
