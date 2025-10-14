function eArabic(x){
  return x.toLocaleString('ar-EG');
}

console.log(eArabic(123456.789));
// expected output: "١٢٣٬٤٥٦٫٧٨٩"

console.log(eArabic("123456.789"));
// expected output: "123456.789"

console.log(eArabic(NaN));
<<<<<<< HEAD
// expected output: "ليس رقم"
=======
// expected output: "ليس رقم"
>>>>>>> origin/develop
