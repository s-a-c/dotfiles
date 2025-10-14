class Replace1 {
  constructor(value) {
    this.value = value;
  }
  [Symbol.replace](string) {
    return `s/${string}/${this.value}/g`;
  }
}

console.log('foo'.replace(new Replace1('bar')));
<<<<<<< HEAD
// expected output: "s/foo/bar/g"
=======
// expected output: "s/foo/bar/g"
>>>>>>> origin/develop
