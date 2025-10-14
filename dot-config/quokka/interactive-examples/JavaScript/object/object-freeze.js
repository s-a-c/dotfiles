const obj = {
  prop: 42
};

Object.freeze(obj);

obj.prop = 33;
// Throws an error in strict mode

console.log(obj.prop);
<<<<<<< HEAD
// expected output: 42
=======
// expected output: 42
>>>>>>> origin/develop
