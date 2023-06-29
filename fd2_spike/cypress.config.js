/* eslint-disable no-undef */
const { defineConfig } = require('cypress')

module.exports = defineConfig({
  screenshotOnRunFailure: false,
  video: false,
  trashAssetsBeforeRuns: true,
  e2e: {
    specPattern: 'src/**/*.cy.js',
    baseUrl: 'http://localhost:5173',
  },
  component: {
    specPattern: 'src/**/*.cy.comp.js',
    devServer: {
      framework: 'vue',
      bundler: 'vite',
    },
  },
})
