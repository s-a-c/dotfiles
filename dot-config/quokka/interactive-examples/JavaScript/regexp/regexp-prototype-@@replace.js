class RegExp1 extends RegExp {
  [Symbol.replace](str) {
    return RegExp.prototype[Symbol.replace].call(this, str, '#!@?');
  }
}

console.log('football'.replace(new RegExp1('foo')));
<<<<<<< HEAD
// expected output: "#!@?tball"
=======
// expected output: "#!@?tball"
>>>>>>> origin/develop
