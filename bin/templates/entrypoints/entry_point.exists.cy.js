/* eslint-disable no-undef */

// https://on.cypress.io/api

describe('Check that entry point exists.', () => {
  it('Check that the page loaded in the dev server.', () => {
    Cypress.config('baseUrl', 'http://localhost:5173')

    cy.visit('/%ENTRY_POINT%/%ENTRY_POINT%.html')

    cy.waitForPage()
  })

  it('Check that the page loaded in the preview server.', () => {
    Cypress.config('baseUrl', 'http://localhost:4173')

    cy.visit('/%ENTRY_POINT%/%ENTRY_POINT%.html')

    cy.waitForPage()
  })

  it('Check that the page loaded in the farmOS server.', () => {
    Cypress.config('baseUrl', 'http://farmOS')

    cy.visit('/%ENTRY_POINT%/%ENTRY_POINT%.html')

    cy.waitForPage()
  })
})
