function getVowels(str) {
  const m = str.match(/[aeiou]/gi);
  if (m === null) {
    return 0;
  }
  return m.length;
}

console.log(getVowels('sky'));
<<<<<<< HEAD
// expected output: 0
=======
// expected output: 0
>>>>>>> origin/develop
