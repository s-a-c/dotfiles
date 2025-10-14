function sanitise(x) {
  if (isNaN(x)) {
    return NaN;
  }
  return x;
}

console.log(sanitise('1'));
// expected output: "1"

console.log(sanitise('NotANumber'));
<<<<<<< HEAD
// expected output: NaN
=======
// expected output: NaN
>>>>>>> origin/develop
