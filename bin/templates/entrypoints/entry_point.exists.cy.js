/* eslint-disable no-undef */

// https://on.cypress.io/api

describe('Check that entry point exists.', () => {
  it('Check that the page loaded.', () => {
    cy.visit('/%ENTRY_POINT%/')

    cy.waitForPage()
  })
})
