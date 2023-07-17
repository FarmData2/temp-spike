/* eslint-disable no-undef */

// https://on.cypress.io/api

describe('Check that entry point exists.', () => {
  it('Check that the page loaded.', () => {
    cy.login('admin', 'admin')

    // maybe move this whole if into the cypress login command?
    // let baseURL = Cypress.config().baseUrl
    // if (baseURL.includes('farmos')) {
    //   // do a login...
    //   console.log('NEED TO LOGIN HERE...')
    // }

    cy.visit('/fd2/main/')
    cy.waitForPage()
  })
})
