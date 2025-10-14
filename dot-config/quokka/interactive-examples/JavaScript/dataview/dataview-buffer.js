//create an ArrayBuffer
const buffer = new ArrayBuffer(123);

// Create a view
const view = new DataView(buffer);

console.log(view.buffer.byteLength);
<<<<<<< HEAD
// expected output: 123
=======
// expected output: 123
>>>>>>> origin/develop
