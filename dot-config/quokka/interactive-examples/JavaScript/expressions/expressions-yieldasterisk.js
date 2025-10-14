function* func1() {
  yield 42;
}

function* func2() {
  yield* func1();
}

const iterator = func2();

console.log(iterator.next().value);
<<<<<<< HEAD
// expected output: 42
=======
// expected output: 42
>>>>>>> origin/develop
