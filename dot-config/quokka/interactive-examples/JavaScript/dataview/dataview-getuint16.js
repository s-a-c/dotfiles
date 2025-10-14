// create an ArrayBuffer with a size in bytes
const buffer = new ArrayBuffer(16);

const view = new DataView(buffer);
view.setUint16(1, 65535); // (max unsigned 16-bit integer)

console.log(view.getUint16(1));
<<<<<<< HEAD
// expected output: 65535
=======
// expected output: 65535
>>>>>>> origin/develop
