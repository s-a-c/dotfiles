// create an ArrayBuffer with a size in bytes
const buffer = new ArrayBuffer(16);

const view = new DataView(buffer);
view.setUint8(1, 255); // (max unsigned 8-bit integer)

console.log(view.getUint8(1));
<<<<<<< HEAD
// expected output: 255
=======
// expected output: 255
>>>>>>> origin/develop
