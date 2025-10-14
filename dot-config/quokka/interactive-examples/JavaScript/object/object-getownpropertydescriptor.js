const object1 = {
  property1: 42
}

const descriptor1 = Object.getOwnPropertyDescriptor(object1, 'property1');

console.log(descriptor1.configurable);
// expected output: true

console.log(descriptor1.value);
<<<<<<< HEAD
// expected output: 42
=======
// expected output: 42
>>>>>>> origin/develop
