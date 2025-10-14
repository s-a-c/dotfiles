function isNegative(element, index, array) {
  return element < 0;
}

const int8 = new Int8Array([-10, -20, -30, -40, -50]);

console.log(int8.every(isNegative));
<<<<<<< HEAD
// expected output: true
=======
// expected output: true
>>>>>>> origin/develop
