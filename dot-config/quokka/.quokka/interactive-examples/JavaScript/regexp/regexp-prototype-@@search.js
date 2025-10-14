class RegExp1 extends RegExp {
  constructor(str) {
    super(str)
    this.pattern = str;
  }
  [Symbol.search](str) {
    return str.indexOf(this.pattern);
  }
}

console.log('table football'.search(new RegExp1('foo')));
<<<<<<< HEAD
// expected output: 6
=======
// expected output: 6
>>>>>>> origin/develop
