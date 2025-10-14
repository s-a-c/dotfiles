var language = {
  set current(name) {
    this.log.push(name);
  },
  log: []
}

language.current = 'EN';
language.current = 'FA';

console.log(language.log);
<<<<<<< HEAD
// expected output: Array ["EN", "FA"]
=======
// expected output: Array ["EN", "FA"]
>>>>>>> origin/develop
