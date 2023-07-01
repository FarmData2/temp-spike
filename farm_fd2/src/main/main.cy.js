// https://on.cypress.io/api

describe('My First Test', () => {
  it('visits the app root url', () => {
    cy.visit('/main/main.html')
    cy.contains('h1', 'You did it')
  })
})
