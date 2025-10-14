function typeOfNaN(x) {
  if (Number.isNaN(x)) {
    return 'Number NaN';
  }
  if (isNaN(x)) {
    return 'NaN';
  }
}

console.log(typeOfNaN('100F'));
// expected output: "NaN"

console.log(typeOfNaN(NaN));
<<<<<<< HEAD
// expected output: "Number NaN"
=======
// expected output: "Number NaN"
>>>>>>> origin/develop
