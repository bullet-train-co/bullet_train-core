import { Controller } from "@hotwired/stimulus"
require("daterangepicker/daterangepicker.css");

// requires jQuery, moment, might want to consider a vanilla JS alternative
import jquery from "jquery";
import 'daterangepicker';
import moment from 'moment-timezone'


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

  connect() {
    this.initPluginInstance()
  }

  disconnect() {
    this.teardownPluginInstance()
  }

  clearDate(event) {
    // don't submit the form, unless it originated from the cancel/clear button
    event.preventDefault()

    jquery(this.fieldTarget).val('')
    jquery(this.displayFieldTarget).val('')
  }

  currentTimeZone(){
    return (
      ( this.hasTimeZoneSelectWrapperTarget && jquery(this.timeZoneSelectWrapperTarget).is(":visible") && this.timeZoneSelectTarget.value ) ||
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
    jquery(this.displayFieldTarget).val(displayVal)
    jquery(this.fieldTarget).val(dataVal)
    // bubble up a change event when the input is updated for other listeners
    if(picker){
      this.displayFieldTarget.dispatchEvent(new CustomEvent('change', { detail: { picker: picker }}))
    }
  }

  showTimeZoneButtons(event) {
    // don't follow the anchor
    event.preventDefault()

    jquery(this.currentTimeZoneWrapperTarget).toggleClass('hidden')
    jquery(this.timeZoneButtonsTarget).toggleClass('hidden')
  }

  // triggered on other click from the timezone buttons
  showTimeZoneSelectWrapper(event) {
    // don't follow the anchor
    event.preventDefault()

    jquery(this.timeZoneButtonsTarget).toggleClass('hidden')
    if (this.hasTimeZoneSelectWrapperTarget) {
      jquery(this.timeZoneSelectWrapperTarget).toggleClass('hidden')
    }
    if(!["", null].includes(this.fieldTarget.value)){
      jquery(this.displayFieldTarget).trigger("apply.daterangepicker");
    }
  }

  resetTimeZoneUI(e) {
    e && e.preventDefault()

    jquery(this.currentTimeZoneWrapperTarget).removeClass('hidden')
    jquery(this.timeZoneButtonsTarget).addClass('hidden')

    if (this.hasTimeZoneSelectWrapperTarget) {
      jquery(this.timeZoneSelectWrapperTarget).addClass('hidden')
    }
  }

  // triggered on selecting a new timezone using the buttons
  setTimeZone(event) {
    // don't follow the anchor
    event.preventDefault()
    const currentTimeZoneEl = this.currentTimeZoneWrapperTarget.querySelector('a')
    jquery(this.timeZoneFieldTarget).val(event.target.dataset.value)
    jquery(currentTimeZoneEl).text(event.target.dataset.label)
    jquery('.time-zone-button').removeClass('button').addClass('button-alternative')
    jquery(event.target).removeClass('button-alternative').addClass('button')
    this.resetTimeZoneUI()
    if(!["", null].includes(this.fieldTarget.value)){
      jquery(this.displayFieldTarget).trigger("apply.daterangepicker");
    }
  }

  // triggered on selecting a new timezone from the timezone picker
  selectTimeZoneChange(event) {
    if(!["", null].includes(this.fieldTarget.value)){
      jquery(this.displayFieldTarget).trigger("apply.daterangepicker");
    }
  }

  // triggered on cancel click from the timezone picker
  cancelSelect(event) {
    event.preventDefault()
    this.resetTimeZoneUI()
    if(!["", null].includes(this.fieldTarget.value)){
      jquery(this.displayFieldTarget).trigger("apply.daterangepicker")
    }
  }

  displayFieldChange(event) {
    const newTimeZone = this.currentTimeZone()
    const format = this.includeTimeValue ? this.timeFormatValue : this.dateFormatValue
    const momentParsed = moment(this.displayFieldTarget.value, format, false)
    if(momentParsed.isValid()){
      const momentVal = moment.tz(momentParsed.format("YYYY-MM-DDTHH:mm"), newTimeZone)
      const dataVal = this.includeTimeValue ? momentVal.toISOString(true) : momentVal.format('YYYY-MM-DD')
      jquery(this.fieldTarget).val(dataVal)
    } else {
      // nullify field value when the display format is wrong
      jquery(this.fieldTarget).val("")
    }
  }

  initPluginInstance() {
    const localeValues = this.pickerLocaleValue
    const isAmPm = this.isAmPmValue
    localeValues['format'] = this.includeTimeValue ? this.timeFormatValue : this.dateFormatValue

    jquery(this.displayFieldTarget).daterangepicker({
      singleDatePicker: true,
      timePicker: this.includeTimeValue,
      timePickerIncrement: 5,
      autoUpdateInput: false,
      locale: localeValues,
      timePicker24Hour: !isAmPm,
    })

    jquery(this.displayFieldTarget).on('apply.daterangepicker', this.applyDateToField.bind(this))
    jquery(this.displayFieldTarget).on('cancel.daterangepicker', this.clearDate.bind(this))
    jquery(this.displayFieldTarget).on('input', this,this.displayFieldChange.bind(this));

    this.pluginMainEl = this.displayFieldTarget
    this.plugin = jquery(this.pluginMainEl).data('daterangepicker') // weird

    // Init time zone select
    if (this.includeTimeValue && this.hasTimeZoneSelectWrapperTarget) {
      this.timeZoneSelect = this.timeZoneSelectWrapperTarget.querySelector('select.select2')

      jquery(this.timeZoneSelect).select2({
        width: 'style'
      })

      const self = this

      jquery(this.timeZoneSelect).on('change.select2', function(event) {
        const currentTimeZoneEl = self.currentTimeZoneWrapperTarget.querySelector('a')
        const {value} = event.target
        jquery(self.timeZoneFieldTarget).val(value)
        jquery(currentTimeZoneEl).text(value)

        const selectedOptionTimeZoneButton = jquery('.selected-option-time-zone-button')

        if (self.defaultTimeZonesValue.includes(value)) {
          jquery('.time-zone-button').removeClass('button').addClass('button-alternative')
          selectedOptionTimeZoneButton.addClass('hidden').attr('hidden', true)
          jquery(`a[data-value="${value}"`).removeClass('button-alternative').addClass('button')
        } else {
          // deselect any selected button
          jquery('.time-zone-button').removeClass('button').addClass('button-alternative')
          selectedOptionTimeZoneButton.text(value)
          selectedOptionTimeZoneButton.attr('data-value', value).removeAttr('hidden')
          selectedOptionTimeZoneButton.removeClass(['hidden', 'button-alternative']).addClass('button')
        }

        self.resetTimeZoneUI()
      })
    }
  }

  teardownPluginInstance() {
    if (this.plugin === undefined) { return }
    jquery(this.pluginMainEl).off('apply.daterangepicker')
    jquery(this.pluginMainEl).off('cancel.daterangepicker')
    // revert to original markup, remove any event listeners
    this.plugin.remove()

    if (this.includeTimeValue) {
      jquery(this.timeZoneSelect).select2('destroy');
    }
  }
}
