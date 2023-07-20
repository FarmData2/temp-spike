/* eslint-disable no-undef */

describe('Check that the %ENTRY_POINT% entry point exists.', () => {
  it('Check that the page loaded.', () => {
    // Login if running in live farmOS.
    cy.login('admin', 'admin')
    // Go to the main page.
    cy.visit('%DRUPAL_ROUTE%2/')
    // Check that the page loads.
    cy.waitForPage()
  })
})
