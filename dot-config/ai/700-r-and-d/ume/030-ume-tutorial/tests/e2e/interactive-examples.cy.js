/**
 * End-to-end tests for interactive examples
 */

describe('Interactive Examples', () => {
  beforeEach(() => {
    // Visit the page with interactive examples
    cy.visit('/050-implementation/010-phase0-foundation/060-php8-attributes.html');
  });

  it('should load interactive examples', () => {
    // Check if interactive examples are loaded
    cy.get('.interactive-code-example').should('exist');
    cy.get('.example-title').should('contain', 'Creating and Using Basic PHP 8 Attributes');
  });

  it('should initialize Monaco editor', () => {
    // Check if Monaco editor is initialized
    cy.get('.monaco-editor').should('exist');
    cy.get('.monaco-editor .view-lines').should('exist');
  });

  it('should run code and display output', () => {
    // Click the run button
    cy.get('.run-button').first().click();

    // Check if output is displayed
    cy.get('.output-content').should('contain', 'Controller route: GET /users');
  });

  it('should reset code to original', () => {
    // Modify the code
    cy.get('.monaco-editor .view-lines').type('{end}{enter}// Modified code');

    // Click the reset button
    cy.get('.reset-button').first().click();

    // Check if code is reset
    cy.get('.monaco-editor .view-lines').should('not.contain', 'Modified code');
  });

  it('should copy code to clipboard', () => {
    // Mock clipboard API
    cy.window().then((win) => {
      cy.stub(win.navigator.clipboard, 'writeText').resolves();
    });

    // Click the copy button
    cy.get('.copy-button').first().click();

    // Check if clipboard API was called
    cy.window().then((win) => {
      expect(win.navigator.clipboard.writeText).to.be.called;
    });
  });

  it('should handle errors in code', () => {
    // Modify the code to introduce an error
    cy.get('.monaco-editor .view-lines').clear().type('<?php echo $undefinedVariable;');

    // Click the run button
    cy.get('.run-button').first().click();

    // Check if error is displayed
    cy.get('.output-content').should('contain', 'Undefined variable');
  });

  it('should switch themes', () => {
    // Check initial theme
    cy.get('body').should('have.class', 'theme-light');

    // Click the theme toggle button
    cy.get('#theme-toggle').click();

    // Check if theme is switched
    cy.get('body').should('have.class', 'theme-dark');
  });
});
