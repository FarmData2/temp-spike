import Counter from './CounterExample.vue'

describe('Test the counter component', () => {
  it('renders', () => {
    cy.mount(Counter)
  })
})
