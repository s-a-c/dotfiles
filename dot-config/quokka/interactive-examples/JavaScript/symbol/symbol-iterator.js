const iterable1 = new Object();

iterable1[Symbol.iterator] = function* () {
  yield 1;
  yield 2;
  yield 3;
};

console.log([...iterable1]);
<<<<<<< HEAD
// expected output: Array [1, 2, 3]
=======
// expected output: Array [1, 2, 3]
>>>>>>> origin/develop
