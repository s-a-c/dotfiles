# Pluralization Rules

<link rel="stylesheet" href="../../../../assets/css/styles.css">

## Goal

Learn how to handle pluralization in different languages in your UME application, ensuring that messages are grammatically correct regardless of the language.

## Prerequisites

- Completed the [Setting Up Internationalization](./010-setting-up-i18n.md) guide
- Basic understanding of Laravel's translation system
- Basic understanding of pluralization rules in different languages

## Understanding Pluralization

Pluralization is the process of determining the correct form of a word or phrase based on a count. While English has simple pluralization rules (singular for 1, plural for everything else), many languages have more complex rules:

- **English**: Two forms (singular, plural)
  - 1 item
  - 2 items, 5 items, 0 items
  
- **French**: Two forms (singular, plural)
  - 1 élément
  - 2 éléments, 5 éléments, 0 élément
  
- **Russian**: Three forms (for 1, for 2-4, for 5+)
  - 1 элемент
  - 2 элемента, 3 элемента, 4 элемента
  - 5 элементов, 11 элементов, 0 элементов
  
- **Arabic**: Six forms (for 0, 1, 2, 3-10, 11-99, 100+)
  - 0 عنصر
  - 1 عنصر
  - 2 عنصران
  - 3 عناصر, 10 عناصر
  - 11 عنصرًا, 99 عنصرًا
  - 100 عنصر, 101 عنصر

## Implementation Steps

### Step 1: Use Laravel's Translation System for Pluralization

Laravel's translation system includes built-in support for pluralization using the `trans_choice` function or the `choice` directive in Blade templates:

```php
// In PHP
echo trans_choice('messages.apples', 1); // "1 apple"
echo trans_choice('messages.apples', 2); // "2 apples"

// In Blade
@choice('messages.apples', 1) // "1 apple"
@choice('messages.apples', 2) // "2 apples"
```

### Step 2: Create Translation Files with Pluralization Rules

Create translation files with pluralization rules for each language:

**resources/lang/en/messages.php**:
```php
<?php

return [
    'apples' => '{0} No apples|{1} One apple|[2,*] :count apples',
    'items' => '{0} No items|{1} One item|[2,*] :count items',
    'users' => '{0} No users|{1} One user|[2,*] :count users',
    'teams' => '{0} No teams|{1} One team|[2,*] :count teams',
    'notifications' => '{0} No notifications|{1} One notification|[2,*] :count notifications',
    'messages' => '{0} No messages|{1} One message|[2,*] :count messages',
];
```

**resources/lang/fr/messages.php**:
```php
<?php

return [
    'apples' => '{0} Aucune pomme|{1} Une pomme|[2,*] :count pommes',
    'items' => '{0} Aucun élément|{1} Un élément|[2,*] :count éléments',
    'users' => '{0} Aucun utilisateur|{1} Un utilisateur|[2,*] :count utilisateurs',
    'teams' => '{0} Aucune équipe|{1} Une équipe|[2,*] :count équipes',
    'notifications' => '{0} Aucune notification|{1} Une notification|[2,*] :count notifications',
    'messages' => '{0} Aucun message|{1} Un message|[2,*] :count messages',
];
```

**resources/lang/ru/messages.php**:
```php
<?php

return [
    'apples' => '{0} Нет яблок|{1} Одно яблоко|[2,4] :count яблока|[5,*] :count яблок',
    'items' => '{0} Нет элементов|{1} Один элемент|[2,4] :count элемента|[5,*] :count элементов',
    'users' => '{0} Нет пользователей|{1} Один пользователь|[2,4] :count пользователя|[5,*] :count пользователей',
    'teams' => '{0} Нет команд|{1} Одна команда|[2,4] :count команды|[5,*] :count команд',
    'notifications' => '{0} Нет уведомлений|{1} Одно уведомление|[2,4] :count уведомления|[5,*] :count уведомлений',
    'messages' => '{0} Нет сообщений|{1} Одно сообщение|[2,4] :count сообщения|[5,*] :count сообщений',
];
```

**resources/lang/ar/messages.php**:
```php
<?php

return [
    'apples' => '{0} لا توجد تفاحات|{1} تفاحة واحدة|{2} تفاحتان|[3,10] :count تفاحات|[11,99] :count تفاحة|[100,*] :count تفاحة',
    'items' => '{0} لا توجد عناصر|{1} عنصر واحد|{2} عنصران|[3,10] :count عناصر|[11,99] :count عنصرًا|[100,*] :count عنصر',
    'users' => '{0} لا يوجد مستخدمين|{1} مستخدم واحد|{2} مستخدمان|[3,10] :count مستخدمين|[11,99] :count مستخدمًا|[100,*] :count مستخدم',
    'teams' => '{0} لا توجد فرق|{1} فريق واحد|{2} فريقان|[3,10] :count فرق|[11,99] :count فريقًا|[100,*] :count فريق',
    'notifications' => '{0} لا توجد إشعارات|{1} إشعار واحد|{2} إشعاران|[3,10] :count إشعارات|[11,99] :count إشعارًا|[100,*] :count إشعار',
    'messages' => '{0} لا توجد رسائل|{1} رسالة واحدة|{2} رسالتان|[3,10] :count رسائل|[11,99] :count رسالة|[100,*] :count رسالة',
];
```

### Step 3: Use Pluralization in Views

Use pluralization in your views:

```php
<div class="mt-2 text-sm text-gray-500">
    {{ trans_choice('messages.users', $users->count()) }}
</div>

<div class="mt-2 text-sm text-gray-500">
    {{ trans_choice('messages.teams', $teams->count()) }}
</div>

<div class="mt-2 text-sm text-gray-500">
    {{ trans_choice('messages.notifications', $notifications->count()) }}
</div>
```

### Step 4: Use Pluralization with Parameters

You can include parameters in your pluralization strings:

```php
// In translation file
'new_messages' => '{0} You have no new messages|{1} You have 1 new message|[2,*] You have :count new messages',

// In view
<div class="mt-2 text-sm text-gray-500">
    {{ trans_choice('messages.new_messages', $newMessages->count()) }}
</div>
```

### Step 5: Use Pluralization with Multiple Parameters

You can include multiple parameters in your pluralization strings:

```php
// In translation file
'team_members' => '{0} Team :team has no members|{1} Team :team has 1 member|[2,*] Team :team has :count members',

// In view
<div class="mt-2 text-sm text-gray-500">
    {{ trans_choice('messages.team_members', $team->members->count(), ['team' => $team->name]) }}
</div>
```

### Step 6: Create a Helper Function for Complex Pluralization

For more complex pluralization scenarios, you can create a helper function:

```php
// app/Helpers/PluralHelper.php
<?php

namespace App\Helpers;

use Illuminate\Support\Facades\Lang;

class PluralHelper
{
    /**
     * Get the plural form of a word based on a count.
     *
     * @param  string  $key
     * @param  int  $count
     * @param  array  $replace
     * @param  string|null  $locale
     * @return string
     */
    public static function plural($key, $count, array $replace = [], $locale = null)
    {
        $replace['count'] = $count;
        
        return Lang::choice($key, $count, $replace, $locale);
    }
    
    /**
     * Get the plural form of a word with a formatted count.
     *
     * @param  string  $key
     * @param  int  $count
     * @param  array  $replace
     * @param  string|null  $locale
     * @return string
     */
    public static function pluralWithFormattedCount($key, $count, array $replace = [], $locale = null)
    {
        $replace['count'] = number_format($count);
        
        return Lang::choice($key, $count, $replace, $locale);
    }
}
```

Use the helper function in your views:

```php
<div class="mt-2 text-sm text-gray-500">
    {{ App\Helpers\PluralHelper::plural('messages.users', $users->count()) }}
</div>

<div class="mt-2 text-sm text-gray-500">
    {{ App\Helpers\PluralHelper::pluralWithFormattedCount('messages.users', 1000) }}
</div>
```

### Step 7: Create a Blade Directive for Pluralization

Create a Blade directive for easy pluralization in views:

```php
// app/Providers/AppServiceProvider.php
public function boot()
{
    Blade::directive('plural', function ($expression) {
        return "<?php echo App\\Helpers\\PluralHelper::plural($expression); ?>";
    });
    
    Blade::directive('pluralWithFormattedCount', function ($expression) {
        return "<?php echo App\\Helpers\\PluralHelper::pluralWithFormattedCount($expression); ?>";
    });
}
```

Use the directive in your views:

```php
<div class="mt-2 text-sm text-gray-500">
    @plural('messages.users', $users->count())
</div>

<div class="mt-2 text-sm text-gray-500">
    @pluralWithFormattedCount('messages.users', 1000)
</div>
```

### Step 8: Handle Pluralization in JavaScript

For client-side pluralization, you can use the Intl.PluralRules API:

```javascript
// resources/js/pluralization.js
export function getPluralForm(count, locale = document.documentElement.lang) {
    const pluralRules = new Intl.PluralRules(locale);
    return pluralRules.select(count);
}

export function getTranslatedPlural(key, count, replacements = {}, locale = document.documentElement.lang) {
    const pluralForm = getPluralForm(count, locale);
    
    // Assuming you have a translations object with plural forms
    const translations = window.translations || {};
    const pluralForms = translations[key] || {};
    
    let translation = pluralForms[pluralForm] || '';
    
    // Replace placeholders
    Object.keys(replacements).forEach(placeholder => {
        translation = translation.replace(`:${placeholder}`, replacements[placeholder]);
    });
    
    return translation;
}
```

Use the JavaScript pluralization functions in your components:

```javascript
// resources/js/components/PluralizedText.js
import { getTranslatedPlural } from '../pluralization';

export default {
    props: {
        translationKey: {
            type: String,
            required: true
        },
        count: {
            type: Number,
            required: true
        },
        replacements: {
            type: Object,
            default: () => ({})
        }
    },
    computed: {
        text() {
            return getTranslatedPlural(
                this.translationKey,
                this.count,
                { ...this.replacements, count: this.count }
            );
        }
    },
    template: `<span>{{ text }}</span>`
};
```

## Pluralization Rules by Language

Here are the pluralization rules for some common languages:

### English (en)
- **Forms**: 2 (singular, plural)
- **Rules**:
  - Singular: 1
  - Plural: 0, 2-n

### French (fr)
- **Forms**: 2 (singular, plural)
- **Rules**:
  - Singular: 0, 1
  - Plural: 2-n

### Spanish (es)
- **Forms**: 2 (singular, plural)
- **Rules**:
  - Singular: 1
  - Plural: 0, 2-n

### German (de)
- **Forms**: 2 (singular, plural)
- **Rules**:
  - Singular: 1
  - Plural: 0, 2-n

### Russian (ru)
- **Forms**: 3 (for 1, for 2-4, for 5+)
- **Rules**:
  - Form 1: 1, 21, 31, ...
  - Form 2: 2-4, 22-24, 32-34, ...
  - Form 3: 0, 5-20, 25-30, 35-40, ...

### Polish (pl)
- **Forms**: 3 (for 1, for 2-4 except 12-14, for rest)
- **Rules**:
  - Form 1: 1
  - Form 2: 2-4, 22-24, 32-34, ... (but not 12-14, 112-114, ...)
  - Form 3: 0, 5-21, 25-31, ...

### Arabic (ar)
- **Forms**: 6 (for 0, 1, 2, 3-10, 11-99, 100+)
- **Rules**:
  - Form 1: 0
  - Form 2: 1
  - Form 3: 2
  - Form 4: 3-10
  - Form 5: 11-99
  - Form 6: 100+

### Japanese (ja), Chinese (zh), Korean (ko), Thai (th)
- **Forms**: 1 (no pluralization)
- **Rules**:
  - Same form for all numbers

## Best Practices for Pluralization

1. **Use Laravel's Built-in Pluralization**: Laravel's `trans_choice` function and `choice` directive handle pluralization for most languages
2. **Create Comprehensive Translation Files**: Include all plural forms for each language
3. **Test with Different Languages**: Test pluralization with different languages to ensure it works correctly
4. **Consider Zero as a Special Case**: Some languages treat zero as a special case
5. **Use Parameters for Dynamic Content**: Use parameters to include dynamic content in pluralized strings
6. **Format Numbers Appropriately**: Format numbers according to the user's locale
7. **Handle Complex Pluralization Rules**: Create helper functions for languages with complex pluralization rules
8. **Document Pluralization Rules**: Document the pluralization rules for each language for translators

## Verification

To verify that pluralization is working correctly:

1. Switch between different locales and check that pluralized strings are displayed correctly
2. Test with different counts (0, 1, 2, 5, 10, 100) to ensure that the correct plural form is used
3. Test with parameters to ensure that they are replaced correctly
4. Test with languages that have complex pluralization rules to ensure that they are handled correctly

## Troubleshooting

### Incorrect Plural Form

If the wrong plural form is being displayed:

1. Check that the translation string includes all necessary plural forms
2. Verify that the count is being passed correctly to the `trans_choice` function
3. Check that the locale is set correctly

### Missing Parameters

If parameters are not being replaced in pluralized strings:

1. Check that the parameters are being passed correctly to the `trans_choice` function
2. Verify that the parameter names in the translation string match the parameter names in the code

## Next Steps

Now that you've learned how to handle pluralization in different languages, let's move on to [Language Detection](./080-language-detection.md) to learn how to detect the user's preferred language.
