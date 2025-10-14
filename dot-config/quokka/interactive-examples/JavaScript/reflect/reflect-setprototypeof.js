const object1 = {};

console.log(Reflect.setPrototypeOf(object1, Object.prototype));
// expected output: true

console.log(Reflect.setPrototypeOf(object1, null));
// expected output: true

const object2 = {};

console.log(Reflect.setPrototypeOf(Object.freeze(object2), null));
<<<<<<< HEAD
// expected output: false
=======
// expected output: false
>>>>>>> origin/develop
