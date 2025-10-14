const uint8 = new Uint8Array([10, 20, 30, 40, 50]);
const keys = uint8.keys();

keys.next();
keys.next();

console.log(keys.next().value);
<<<<<<< HEAD
// expected output: 2
=======
// expected output: 2
>>>>>>> origin/develop
