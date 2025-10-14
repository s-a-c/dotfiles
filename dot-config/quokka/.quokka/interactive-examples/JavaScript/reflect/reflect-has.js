const object1 = {
  property1: 42
};

console.log(Reflect.has(object1, 'property1'));
// expected output: true

console.log(Reflect.has(object1, 'property2'));
// expected output: false

console.log(Reflect.has(object1, 'toString'));
<<<<<<< HEAD
// expected output: true
=======
// expected output: true
>>>>>>> origin/develop
