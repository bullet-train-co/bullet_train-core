const defaultTheme = require('tailwindcss/defaultTheme')
const colors = require('tailwindcss/colors')

module.exports = {
  content: [
    './app/views/**/*.html.erb',
    './app/helpers/**/*.rb',
    './app/assets/stylesheets/**/*.css',
    './app/javascript/**/*.js',
    './tmp/gems/*/app/views/**/*.html.erb',
    './tmp/gems/*/app/helpers/**/*.rb',
    './tmp/gems/*/app/assets/stylesheets/**/*.css',
    './tmp/gems/*/app/javascript/**/*.js',
  ],
  darkMode: 'media',
  theme: {
    extend: {
      fontSize: {
        'xs': '.81rem',
      },
      colors: {
        red: {
          400: '#ee8989',
          500: '#e86060',
          900: '#652424',
        },

        yellow: {
          400: '#fcedbe',
          500: '#fbe6a8',
          900: '#6e6446',
        },

        primary: {
          300: 'var(--primary-300)',
          400: 'var(--primary-400)',
          500: 'var(--primary-500)',
          600: 'var(--primary-600)',
          700: 'var(--primary-700)',
          800: 'var(--primary-800)',
          900: 'var(--primary-900)',
        },

        darkPrimary: {
          300: 'var(--dark-primary-300)',
          400: 'var(--dark-primary-400)',
          500: 'var(--dark-primary-500)',
          600: 'var(--dark-primary-600)',
          700: 'var(--dark-primary-700)',
          800: 'var(--dark-primary-800)',
          900: 'var(--dark-primary-900)',
        },

        secondary: {
          300: 'var(--secondary-300)',
          400: 'var(--secondary-400)',
          500: 'var(--secondary-500)',
          600: 'var(--secondary-600)',
          700: 'var(--secondary-700)',
          800: 'var(--secondary-800)',
          900: 'var(--secondary-900)',
        },

        darkSecondary: {
          300: 'var(--dark-secondary-300)',
          400: 'var(--dark-secondary-400)',
          500: 'var(--dark-secondary-500)',
          600: 'var(--dark-secondary-600)',
          700: 'var(--dark-secondary-700)',
          800: 'var(--dark-secondary-800)',
          900: 'var(--dark-secondary-900)',
        },

        // This is a weird one-off for dark-mode.
        darkAccent: {
          200: 'var(--dark-accent-200)',
        },

        black: {
          100: '#000000',
          200: '#101112',
          300: '#171818',
          400: '#292b2c',
          DEFAULT: '#000000',
        }
      },
      fontFamily: {
        // "Avenir Next W01", "Proxima Nova W01", "", -apple-system, system-ui, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif
        sans: ['Inter var', ...defaultTheme.fontFamily.sans],
      },
    },
  },
  variants: {
    extend: {},
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
  ],
}
