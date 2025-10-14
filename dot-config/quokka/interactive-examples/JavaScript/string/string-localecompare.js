var a = 'réservé'; // with accents, lowercase
var b = 'RESERVE'; // no accents, uppercase

console.log(a.localeCompare(b));
// expected output: 1
console.log(a.localeCompare(b, 'en', {sensitivity: 'base'}));
<<<<<<< HEAD
// expected output: 0
=======
// expected output: 0
>>>>>>> origin/develop
