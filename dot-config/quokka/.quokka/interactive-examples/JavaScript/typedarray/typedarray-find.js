function isNegative(element, index, array) {
  return element < 0;
}

const int8 = new Int8Array([10, 0, -10, 20, -30, 40, -50]);

console.log(int8.find(isNegative));
<<<<<<< HEAD
// expected output: -10
=======
// expected output: -10
>>>>>>> origin/develop
