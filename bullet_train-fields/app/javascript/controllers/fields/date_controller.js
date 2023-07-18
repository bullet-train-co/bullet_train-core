import { Controller } from "@hotwired/stimulus"
require("daterangepicker/daterangepicker.css");

// requires jQuery, moment, might want to consider a vanilla JS alternative
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

    $(this.fieldTarget).val('')
    $(this.displayFieldTarget).val('')
  }

  applyDateToField(event, picker) {
    const format = this.includeTimeValue ? this.timeFormatValue : this.dateFormatValue
    const tz = (
      ( this.hasTimeZoneFieldTarget && this.timeZoneFieldTarget.value ) || this.currentTimeZoneValue
    )
    const momentVal = (
      picker ?
      moment(picker.startDate.toISOString()).tz(tz, true) :
      moment(this.fieldTarget.value).tz(this.timeZoneFieldTarget.value, false)
    )
    const displayVal = momentVal.format(format)
    const dataVal = this.includeTimeValue ? momentVal.toISOString() : momentVal.format('YYYY-MM-DD')
    $(this.displayFieldTarget).val(displayVal)
    $(this.fieldTarget).val(dataVal)
    // bubble up a change event when the input is updated for other listeners
    if(picker){
      this.displayFieldTarget.dispatchEvent(new CustomEvent('change', { detail: { picker: picker }}))
    }
  }

  showTimeZoneButtons(event) {
    // don't follow the anchor
    event.preventDefault()

    $(this.currentTimeZoneWrapperTarget).toggleClass('hidden')
    $(this.timeZoneButtonsTarget).toggleClass('hidden')
  }

  showTimeZoneSelectWrapper(event) {
    // don't follow the anchor
    event.preventDefault()

    $(this.timeZoneButtonsTarget).toggleClass('hidden')

    if (this.hasTimeZoneSelectWrapperTarget) {
      $(this.timeZoneSelectWrapperTarget).toggleClass('hidden')
    }
    const tz = this.timeZoneSelectTarget.value
    const format = this.includeTimeValue ? this.timeFormatValue : this.dateFormatValue
    const momentVal = moment(this.fieldTarget.value).tz(tz, false)
    const displayVal = momentVal.format(format)
    $(this.displayFieldTarget).val(displayVal)
  }

  resetTimeZoneUI(e) {
    e && e.preventDefault()

    $(this.currentTimeZoneWrapperTarget).removeClass('hidden')
    $(this.timeZoneButtonsTarget).addClass('hidden')

    if (this.hasTimeZoneSelectWrapperTarget) {
      $(this.timeZoneSelectWrapperTarget).addClass('hidden')
    }
  }

  // used by the timezone buttons
  setTimeZone(event) {
    // don't follow the anchor
    event.preventDefault()
    const currentTimeZoneEl = this.currentTimeZoneWrapperTarget.querySelector('a')
    $(this.timeZoneFieldTarget).val(event.target.dataset.value)
    $(currentTimeZoneEl).text(event.target.dataset.label)
    $('.time-zone-button').removeClass('button').addClass('button-alternative')
    $(event.target).removeClass('button-alternative').addClass('button')
    this.resetTimeZoneUI()
    this.applyDateToField(null, null)
  }

  // used by the timezone picker
  selectTzChange(event) {
    $(this.timeZoneFieldTarget).val(this.timeZoneSelectTarget.value)
    this.applyDateToField(null, null)
  }

  cancelSelect(event) {
    event.preventDefault()
    const format = this.includeTimeValue ? this.timeFormatValue : this.dateFormatValue
    const momentVal = moment(this.fieldTarget.value).tz(this.currentTimeZoneValue, false)
    const displayVal = momentVal.format(format)
    $(this.displayFieldTarget).val(displayVal)
    this.resetTimeZoneUI()
  }

  initPluginInstance() {
    const t = this.pickerLocaleValue
    const isAmPm = this.isAmPmValue
    var localeValues = JSON.parse(JSON.stringify(t))
    localeValues['format'] = this.includeTimeValue ? this.timeFormatValue : this.dateFormatValue

    $(this.displayFieldTarget).daterangepicker({
      singleDatePicker: true,
      timePicker: this.includeTimeValue,
      timePickerIncrement: 5,
      autoUpdateInput: false,
      locale: localeValues,
      timePicker24Hour: !isAmPm,
    })

    $(this.displayFieldTarget).on('apply.daterangepicker', this.applyDateToField.bind(this))
    $(this.displayFieldTarget).on('cancel.daterangepicker', this.clearDate.bind(this))

    this.pluginMainEl = this.displayFieldTarget
    this.plugin = $(this.pluginMainEl).data('daterangepicker') // weird

    // Init time zone select
    if (this.includeTimeValue && this.hasTimeZoneSelectWrapperTarget) {
      this.timeZoneSelect = this.timeZoneSelectWrapperTarget.querySelector('select.select2')

      $(this.timeZoneSelect).select2({
        width: 'style'
      })

      const self = this

      $(this.timeZoneSelect).on('change.select2', function(event) {
        const currentTimeZoneEl = self.currentTimeZoneWrapperTarget.querySelector('a')
        const {value} = event.target
        $(self.timeZoneFieldTarget).val(value)
        $(currentTimeZoneEl).text(value)

        const selectedOptionTimeZoneButton = $('.selected-option-time-zone-button')

        if (self.defaultTimeZonesValue.includes(value)) {
          $('.time-zone-button').removeClass('button').addClass('button-alternative')
          selectedOptionTimeZoneButton.addClass('hidden').attr('hidden', true)
          $(`a[data-value="${value}"`).removeClass('button-alternative').addClass('button')
        } else {
          // deselect any selected button
          $('.time-zone-button').removeClass('button').addClass('button-alternative')
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
    $(this.pluginMainEl).off('apply.daterangepicker')
    $(this.pluginMainEl).off('cancel.daterangepicker')
    // revert to original markup, remove any event listeners
    this.plugin.remove()

    if (this.includeTimeValue) {
      $(this.timeZoneSelect).select2('destroy');
    }
  }
}
