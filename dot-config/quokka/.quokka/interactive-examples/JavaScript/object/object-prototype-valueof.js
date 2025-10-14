function MyNumberType(n) {
  this.number = n;
}

MyNumberType.prototype.valueOf = function() {
  return this.number;
};

const object1 = new MyNumberType(4);

console.log(object1 + 3);
<<<<<<< HEAD
// expected output: 7
=======
// expected output: 7
>>>>>>> origin/develop
