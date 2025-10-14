const object1 = {
  [Symbol.toPrimitive](hint) {
    if (hint == 'number') {
      return 42;
    }
    return null;
  }
};

console.log(+object1);
<<<<<<< HEAD
// expected output: 42
=======
// expected output: 42
>>>>>>> origin/develop
