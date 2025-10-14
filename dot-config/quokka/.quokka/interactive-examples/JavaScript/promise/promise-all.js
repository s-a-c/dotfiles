var promise1 = Promise.resolve(3);
var promise2 = 42;
var promise3 = new Promise(function(resolve, reject) {
  setTimeout(resolve, 100, 'foo');
});

Promise.all([promise1, promise2, promise3]).then(function(values) {
  console.log(values);
});
<<<<<<< HEAD
// expected output: Array [3, 42, "foo"]
=======
// expected output: Array [3, 42, "foo"]
>>>>>>> origin/develop
