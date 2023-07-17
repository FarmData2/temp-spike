/* eslint-disable no-undef */

const { defineConfig } = require('cypress')

module.exports = defineConfig({
  screenshotOnRunFailure: false,
  video: false,
  trashAssetsBeforeRuns: true,
  e2e: {
    specPattern: 'src/entrypoints/**/*.cy.js',
  },
  component: {
    specPattern: '../../components/**/*.comp.cy.js',
    devServer: {
      framework: 'vue',
      bundler: 'vite',
    },
  },
})
