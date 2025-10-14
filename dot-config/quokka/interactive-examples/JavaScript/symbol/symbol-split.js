class Split1 {
  constructor(value) {
    this.value = value;
  }
  [Symbol.split](string) {
    var index = string.indexOf(this.value);
    return this.value + string.substr(0, index) + "/"
      + string.substr(index + this.value.length);
  }
}

console.log('foobar'.split(new Split1('foo')));
<<<<<<< HEAD
// expected output: "foo/bar"
=======
// expected output: "foo/bar"
>>>>>>> origin/develop
