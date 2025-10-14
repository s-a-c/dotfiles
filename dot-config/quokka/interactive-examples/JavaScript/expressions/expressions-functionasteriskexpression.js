function* foo() {
  yield 'a';
  yield 'b';
  yield 'c';
}

var str = "";
for (let val of foo()) {
  str = str + val;
}

console.log(str);
<<<<<<< HEAD
// expected output: "abc"
=======
// expected output: "abc"
>>>>>>> origin/develop
