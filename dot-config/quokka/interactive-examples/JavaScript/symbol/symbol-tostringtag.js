class ValidatorClass {
  get [Symbol.toStringTag]() {
    return 'Validator';
  }
}

console.log(Object.prototype.toString.call(new ValidatorClass()));
<<<<<<< HEAD
// expected output: "[object Validator]"
=======
// expected output: "[object Validator]"
>>>>>>> origin/develop
