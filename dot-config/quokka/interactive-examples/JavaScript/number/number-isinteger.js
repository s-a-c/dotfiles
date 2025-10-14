function fits(x, y) {
  if (Number.isInteger(y / x)) {
    return 'Fits!';
  }
  return 'Does NOT fit!';
}

console.log(fits(5, 10));
// expected output: "Fits!"

console.log(fits(5, 11));
<<<<<<< HEAD
// expected output: "Does NOT fit!"
=======
// expected output: "Does NOT fit!"
>>>>>>> origin/develop
