function div(x) {
  if (isFinite(1000 / x)) {
    return 'Number is NOT Infinity.';
  }
  return "Number is Infinity!";
}

console.log(div(0));
// expected output: "Number is Infinity!""

console.log(div(1));
<<<<<<< HEAD
// expected output: "Number is NOT Infinity."
=======
// expected output: "Number is NOT Infinity."
>>>>>>> origin/develop
