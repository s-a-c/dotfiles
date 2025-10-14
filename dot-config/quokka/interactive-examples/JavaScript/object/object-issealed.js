const object1 = {
  property1: 42
};

console.log(Object.isSealed(object1));
// expected output: false

Object.seal(object1);

console.log(Object.isSealed(object1));
<<<<<<< HEAD
// expected output: true
=======
// expected output: true
>>>>>>> origin/develop
