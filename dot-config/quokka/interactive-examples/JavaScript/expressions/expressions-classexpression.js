var Rectangle = class {
  constructor(height, width) {
    this.height = height;
    this.width = width;
  }
  area() {
    return this.height * this.width;
  }
}

console.log(new Rectangle(5,8).area());
<<<<<<< HEAD
// expected output: 40
=======
// expected output: 40
>>>>>>> origin/develop
