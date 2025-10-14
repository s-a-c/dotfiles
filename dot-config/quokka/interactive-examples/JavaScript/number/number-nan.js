function clean(x) {
  if (x === Number.NaN) {
    // can never be true
    return null;
  }
  if (isNaN(x)) {
    return 0;
  }
}

console.log(clean(Number.NaN));
<<<<<<< HEAD
// expected output: 0
=======
// expected output: 0
>>>>>>> origin/develop
