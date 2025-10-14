const set1 = new Set();
var object1 = new Object();

set1.add(42);
set1.add('forty two');
set1.add('forty two');
set1.add(object1);

console.log(set1.size);
<<<<<<< HEAD
// expected output: 3
=======
// expected output: 3
>>>>>>> origin/develop
