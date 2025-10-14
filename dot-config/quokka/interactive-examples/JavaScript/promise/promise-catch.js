var promise1 = new Promise(function(resolve, reject) {
  throw 'Uh-oh!';
});

promise1.catch(function(error) {
  console.error(error);
});
<<<<<<< HEAD
// expected output: Uh-oh!
=======
// expected output: Uh-oh!
>>>>>>> origin/develop
