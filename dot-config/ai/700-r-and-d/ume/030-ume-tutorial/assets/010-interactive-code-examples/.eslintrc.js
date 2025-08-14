/**
 * ESLint configuration for UME Tutorial Interactive Code Examples
 */

module.exports = {
  env: {
    browser: true,
    es2021: true,
    node: true,
    jest: true
  },
  extends: 'eslint:recommended',
  parserOptions: {
    ecmaVersion: 12,
    sourceType: 'module'
  },
  rules: {
    // Possible Errors
    'no-console': 'warn',
    'no-debugger': 'warn',
    
    // Best Practices
    'eqeqeq': ['error', 'always'],
    'no-eval': 'error',
    'no-implied-eval': 'error',
    'no-alert': 'error',
    
    // Variables
    'no-unused-vars': ['warn', { 
      vars: 'all', 
      args: 'after-used',
      ignoreRestSiblings: true
    }],
    
    // Stylistic Issues
    'indent': ['warn', 2],
    'linebreak-style': ['warn', 'unix'],
    'quotes': ['warn', 'single', { avoidEscape: true }],
    'semi': ['warn', 'always'],
    
    // ES6
    'arrow-spacing': 'warn',
    'no-var': 'warn',
    'prefer-const': 'warn',
    'prefer-template': 'warn'
  }
};
