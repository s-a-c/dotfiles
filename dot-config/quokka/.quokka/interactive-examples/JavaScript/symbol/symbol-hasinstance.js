class Array1 {
  static [Symbol.hasInstance](instance) {
    return Array.isArray(instance);
  }
}

console.log([] instanceof Array1);
<<<<<<< HEAD
// expected output: true
=======
// expected output: true
>>>>>>> origin/develop
