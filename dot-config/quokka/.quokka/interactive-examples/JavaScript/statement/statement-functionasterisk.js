function* generator(i) {
  yield i;
  yield i + 10;
}

var gen = generator(10);

console.log(gen.next().value);
// expected output: 10

console.log(gen.next().value);
<<<<<<< HEAD
// expected output: 20
=======
// expected output: 20
>>>>>>> origin/develop
