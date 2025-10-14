function canMakeHTTPRequest() {
    return typeof globalThis.XMLHttpRequest === 'function';
}

console.log(canMakeHTTPRequest());
<<<<<<< HEAD
// expected output: false
=======
// expected output: false
>>>>>>> origin/develop
