var promise1 = new Promise(function(resolve, reject) {
  setTimeout(function() {
    resolve('foo');
  }, 300);
});

promise1.then(function(value) {
  console.log(value);
  // expected output: "foo"
});

console.log(promise1);
<<<<<<< HEAD
// expected output: [object Promise]
=======
// expected output: [object Promise]
>>>>>>> origin/develop
