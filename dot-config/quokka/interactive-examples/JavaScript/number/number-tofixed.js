function financial(x) {
  return Number.parseFloat(x).toFixed(2);
}

console.log(financial(123.456));
// expected output: "123.46"

console.log(financial(0.004));
// expected output: "0.00"

console.log(financial('1.23e+5'));
<<<<<<< HEAD
// expected output: "123000.00"
=======
// expected output: "123000.00"
>>>>>>> origin/develop
