var str = "";

loop1:
for (var i = 0; i < 5; i++) {
  if (i === 1) {
    continue loop1;
  }
  str = str + i;
}

console.log(str);
<<<<<<< HEAD
// expected output: "0234"
=======
// expected output: "0234"
>>>>>>> origin/develop
