import Counter from './CounterExample.vue'

describe('Test the counter component', () => {
  it('The component renders', () => {
    cy.mount(Counter)
  })
})
