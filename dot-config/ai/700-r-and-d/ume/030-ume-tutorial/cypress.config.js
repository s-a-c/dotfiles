/**
 * Cypress configuration for interactive examples end-to-end tests
 */

module.exports = {
  e2e: {
    baseUrl: 'http://localhost:3000',
    specPattern: 'tests/e2e/**/*.cy.{js,jsx,ts,tsx}',
    supportFile: 'tests/e2e/support/e2e.js',
    viewportWidth: 1280,
    viewportHeight: 720
  }
};
