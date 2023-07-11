import { Controller } from "@hotwired/stimulus"
require("daterangepicker/daterangepicker.css");

// requires jQuery, moment, might want to consider a vanilla JS alternative
import 'daterangepicker';
import moment from 'moment-timezone'
import { rubyTzNameToUnixTz } from '../../utils'

export default class extends Controller {
  static targets = [ "field", "displayField", "clearButton", "currentTimeZoneWrapper", "timeZoneButtons", "timeZoneSelectWrapper", "timeZoneField" ]
  static values = {
    includeTime: Boolean,
    defaultTimeZones: Array,
    cancelButtonLabel: { type: String, default: "Cancel" },
    applyButtonLabel: { type: String, default: "Apply" },
    dateFormat: String,
    timeFormat: String,
    currentTimeZone: String,
    isAmPm: Boolean,
    t: { type: Object, default: {} }
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
    const pickerMomentVal = picker.startDate
    const momentVal = moment(pickerMomentVal.toISOString()).tz(rubyTzNameToUnixTz[this.currentTimeZoneValue], true)
    const displayVal = momentVal.format(format)
    const dataVal = this.includeTimeValue ? momentVal.toISOString() : momentVal.format('YYYY-MM-DD')
    $(this.displayFieldTarget).val(displayVal)
    $(this.fieldTarget).val(dataVal)
    // bubble up a change event when the input is updated for other listeners
    this.displayFieldTarget.dispatchEvent(new CustomEvent('change', { detail: { picker: picker }}))
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
  }

  resetTimeZoneUI(e) {
    e && e.preventDefault()

    $(this.currentTimeZoneWrapperTarget).removeClass('hidden')
    $(this.timeZoneButtonsTarget).addClass('hidden')

    if (this.hasTimeZoneSelectWrapperTarget) {
      $(this.timeZoneSelectWrapperTarget).addClass('hidden')
    }
  }

  setTimeZone(event) {
    // don't follow the anchor
    event.preventDefault()

    const currentTimeZoneEl = this.currentTimeZoneWrapperTarget.querySelector('a')
    const {value} = event.target.dataset

    $(this.timeZoneFieldTarget).val(value)
    $(currentTimeZoneEl).text(value)

    $('.time-zone-button').removeClass('button').addClass('button-alternative')
    $(event.target).removeClass('button-alternative').addClass('button')

    this.resetTimeZoneUI()
  }

  initPluginInstance() {
    const t = this.tValue
    const isAmPm = this.isAmPmValue
    var localeValues = JSON.parse(JSON.stringify(t))
    localeValues['format'] = this.includeTimeValue ? this.timeFormatValue : this.dateFormatValue
    localeValues['applyLabel'] = this.applyButtonLabelValue
    localeValues['cancelLabel'] = this.cancelButtonLabelValue

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
