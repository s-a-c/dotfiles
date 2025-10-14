const korean = new Intl.Locale('ko', {
  script: 'Kore', region: 'KR', hourCycle: 'h24', calendar: 'gregory'
});

const japanese = new Intl.Locale('ja-Jpan-JP-u-ca-japanese-hc-h12');

console.log(korean.baseName, japanese.baseName);
// expected output: "ko-Kore-KR" "ja-Jpan-JP"

console.log(korean.hourCycle, japanese.hourCycle);
<<<<<<< HEAD
// expected output: "h24" "h12"
=======
// expected output: "h24" "h12"
>>>>>>> origin/develop
