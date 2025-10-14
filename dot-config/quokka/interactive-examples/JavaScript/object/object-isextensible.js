const object1 = {};

console.log(Object.isExtensible(object1));
// expected output: true

Object.preventExtensions(object1);

console.log(Object.isExtensible(object1));
<<<<<<< HEAD
// expected output: false
=======
// expected output: false
>>>>>>> origin/develop
