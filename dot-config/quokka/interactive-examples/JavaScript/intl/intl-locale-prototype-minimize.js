const english = new Intl.Locale("en-Latn-US");
const korean = new Intl.Locale("ko-Kore-KR");
const arabic = new Intl.Locale("ar-Arab-EG");

console.log(english.minimize().baseName);
// expected output: "en"

console.log(korean.minimize().baseName);
// expected output: "ko"

console.log(arabic.minimize().baseName);
<<<<<<< HEAD
// expected output: "ar"
=======
// expected output: "ar"
>>>>>>> origin/develop
