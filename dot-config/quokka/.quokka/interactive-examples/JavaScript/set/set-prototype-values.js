const set1 = new Set();
set1.add(42);
set1.add('forty two');

var iterator1 = set1.values();

console.log(iterator1.next().value);
// expected output: 42

console.log(iterator1.next().value);
<<<<<<< HEAD
// expected output: "forty two"
=======
// expected output: "forty two"
>>>>>>> origin/develop
