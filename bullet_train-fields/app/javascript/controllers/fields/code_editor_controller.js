import { Controller } from '@hotwired/stimulus'
import { version as MONACO_VERSION } from 'monaco-editor/package.json'

const MONACO_LOADED_EVENT = 'monaco:loaded'
const MONACO_ERROR_EVENT = 'monaco:error'
export default class extends Controller {
  static targets = ['plainField', 'codeField']

  static values = {
    language: {
      type: String,
      default: 'javascript' // for all supported languages, see https://github.com/microsoft/monaco-editor/tree/main/src/basic-languages
    },
    themeLight: {
      type: String,
      default: 'vs'
    },
    themeDark: {
      type: String,
      default: 'vs-dark'
    },
    monacoConfig: {
      type: Object,
      default: {}
    }
  }

  connect() {
    this.loadEditorFramework()
  }

  disconnect() {
    this.teardownCodeEditor()
  }

  initCodeEditor() {
    if (!this.hasPlainFieldTarget || !this.hasCodeFieldTarget) return
    if (!this.monacoInstance) return

    this.codeEditor = this.monacoInstance.editor.create(this.codeFieldTarget, {
      value: this.plainFieldTarget.value,
      language: this.languageValue,
      ...this.editorConfig
    })

    this.codeEditor.onDidChangeModelContent(() => {
      this.updatePlainField()
    }) // teardownCodeEditor should properly unregister this event handler
  }

  updatePlainField() {
    this.plainFieldTarget.value = this.codeEditor.getValue()
    this.plainFieldTarget.dispatchEvent(new Event('input', { bubbles: true }))
  }

  get editorConfig() {
    return {
      automaticLayout: true,
      theme: this.theme,
      minimap: { enabled: false },
      scrollBeyondLastLine: false,
      ...this.monacoConfigValue
    }
  }

  showPlainField() {
    this.plainFieldTarget.classList.remove('hidden')
    this.codeFieldTarget.classList.add('hidden')
  }

  teardownCodeEditor() {
    if (this.codeEditor) {
      this.codeEditor.dispose()
      this.codeEditor = null
    }
    document.removeEventListener(MONACO_LOADED_EVENT, this.initCodeEditor)
    document.removeEventListener(MONACO_ERROR_EVENT, this.showPlainField)
  }

  loadEditorFramework() {
    if (!this.hasPlainFieldTarget || !this.hasCodeFieldTarget) return

    // Listen for Monaco load event
    this.initCodeEditor = this.initCodeEditor.bind(this)
    this.showPlainField = this.showPlainField.bind(this)
    document.addEventListener(MONACO_LOADED_EVENT, this.initCodeEditor)
    document.addEventListener(MONACO_ERROR_EVENT, this.showPlainField)
    try {
      if (this.monacoInstance) {
        this.initCodeEditor()
        return
      }

      this.ensureMonacoLoaded()
    } catch (error) {
      console.error('Monaco failed to load:', error)
      this.showPlainField()
    }
  }

  // if you want to include the monaco editor directly, overload this method in the subclass
  // and monacoInstance() getter
  ensureMonacoLoaded() {
    // Check for existing script
    const existingScript = document.querySelector('script[data-monaco-loader]')
    if (!existingScript) {
      const script = document.createElement('script')
      script.src = `https://cdn.jsdelivr.net/npm/monaco-editor@${MONACO_VERSION}/min/vs/loader.js`
      script.dataset.monacoLoader = ''

      script.onload = () => {
        require.config({
          paths: {
            vs: `https://cdn.jsdelivr.net/npm/monaco-editor@${MONACO_VERSION}/min/vs`
          }
        })

        require(['vs/editor/editor.main'], (monaco) => {
          window.monacoInstance = monaco
          document.dispatchEvent(new Event(MONACO_LOADED_EVENT))
        })
      }

      script.onerror = () => {
        try {
          document.dispatchEvent(new Event(MONACO_ERROR_EVENT))
        } catch (error) {
          console.warn(
            'script failed to load and code editor is no longer available',
            error
          )
        }
      }

      document.head.appendChild(script)
    }
  }

  // if you want to include the monaco editor directly, overload this method in the subclass
  // and ensureMonacoLoaded() above
  get monacoInstance() {
    return window.monacoInstance
  }

  watchColorScheme() {
    this.userPrefersDarkSchemeQuery = window.matchMedia(
      '(prefers-color-scheme: dark)'
    )
    this.userPrefersDarkSchemeQuery.addEventListener(
      'change',
      this.updateTheme.bind(this)
    )
  }

  unwatchColorScheme() {
    if (this.userPrefersDarkSchemeQuery === undefined) return
    this.userPrefersDarkSchemeQuery.removeEventListener(
      'change',
      this.updateTheme.bind(this)
    )
    this.userPrefersDarkSchemeQuery = undefined
  }

  updateTheme() {
    this.codeEditor?.updateOptions({ theme: this.theme })
  }

  get userPrefersDarkScheme() {
    return window?.colorScheme?.current === 'dark' || window.matchMedia('(prefers-color-scheme: dark)').matches
  }

  get theme() {
    return this.userPrefersDarkScheme
      ? this.themeDarkValue
      : this.themeLightValue
  }
}
