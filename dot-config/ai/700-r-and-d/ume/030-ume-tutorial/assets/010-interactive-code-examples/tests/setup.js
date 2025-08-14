/**
 * Setup file for Jest tests
 */

// Mock localStorage
const localStorageMock = (function() {
  let store = {};
  
  return {
    getItem: function(key) {
      return store[key] || null;
    },
    setItem: function(key, value) {
      store[key] = value.toString();
    },
    removeItem: function(key) {
      delete store[key];
    },
    clear: function() {
      store = {};
    }
  };
})();

Object.defineProperty(window, 'localStorage', {
  value: localStorageMock
});

// Mock setTimeout and clearTimeout
jest.useFakeTimers();

// Mock fetch
global.fetch = jest.fn(() =>
  Promise.resolve({
    ok: true,
    status: 200,
    json: () => Promise.resolve({}),
    text: () => Promise.resolve('')
  })
);

// Mock DOMParser
global.DOMParser = jest.fn().mockImplementation(() => {
  return {
    parseFromString: jest.fn().mockReturnValue({
      querySelector: jest.fn().mockImplementation(selector => {
        if (selector === 'h1') {
          return { textContent: 'Example Title' };
        }
        if (selector === 'p') {
          return { textContent: 'Example description' };
        }
        if (selector === 'pre code') {
          return { textContent: 'console.log("Example code");' };
        }
        if (selector === '.explanation') {
          return { innerHTML: '<p>Example explanation</p>' };
        }
        return null;
      })
    })
  };
});
