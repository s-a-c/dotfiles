function warn(x) {
  if (Number.isSafeInteger(x)) {
    return 'Precision safe.';
  }
  return 'Precision may be lost!';
}

console.log(warn(Math.pow(2, 53)));
// expected output: "Precision may be lost!"

console.log(warn(Math.pow(2, 53) - 1));
<<<<<<< HEAD
// expected output: "Precision safe."
=======
// expected output: "Precision safe."
>>>>>>> origin/develop
