function resolved(result) {
  console.log('Resolved');
}

function rejected(result) {
  console.error(result);
}

Promise.reject(new Error('fail')).then(resolved, rejected);
<<<<<<< HEAD
// expected output: Error: fail
=======
// expected output: Error: fail
>>>>>>> origin/develop
