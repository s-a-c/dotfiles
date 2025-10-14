var x = 1;

x = (x++, x);

console.log(x);
// expected output: 2

x = (2, 3);

console.log(x);
<<<<<<< HEAD
// expected output: 3
=======
// expected output: 3
>>>>>>> origin/develop
