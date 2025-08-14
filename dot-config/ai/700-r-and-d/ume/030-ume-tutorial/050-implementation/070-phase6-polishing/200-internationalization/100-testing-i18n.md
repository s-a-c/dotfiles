# Testing Internationalized Applications

<link rel="stylesheet" href="../../../../assets/css/styles.css">

## Goal

Learn how to test internationalized applications to ensure that they work correctly for users in different languages and regions.

## Prerequisites

- Completed the [Setting Up Internationalization](./010-setting-up-i18n.md) guide
- Basic understanding of Laravel's testing framework
- Basic understanding of internationalization concepts

## Understanding Internationalization Testing

Testing internationalized applications involves verifying that:

1. **Translations are displayed correctly**: All user-facing text is translated correctly
2. **Locale switching works**: Users can switch between languages
3. **Date and time formatting is correct**: Dates and times are formatted according to the user's locale
4. **Number and currency formatting is correct**: Numbers and currencies are formatted according to the user's locale
5. **Pluralization rules are applied correctly**: Pluralized strings are displayed correctly
6. **RTL layout works**: Right-to-left languages are displayed correctly
7. **Cultural adaptations work**: The application is adapted to different cultures
8. **Legal requirements are met**: The application complies with legal requirements in different regions

## Implementation Steps

### Step 1: Set Up Testing Environment

First, set up your testing environment to support internationalization testing:

```php
// tests/TestCase.php
<?php

namespace Tests;

use Illuminate\Foundation\Testing\TestCase as BaseTestCase;
use Illuminate\Support\Facades\App;

abstract class TestCase extends BaseTestCase
{
    use CreatesApplication;
    
    /**
     * Set the application locale.
     *
     * @param  string  $locale
     * @return $this
     */
    protected function withLocale($locale)
    {
        App::setLocale($locale);
        
        return $this;
    }
    
    /**
     * Set the Accept-Language header.
     *
     * @param  string  $locale
     * @return $this
     */
    protected function withAcceptLanguage($locale)
    {
        $this->withHeader('Accept-Language', $locale);
        
        return $this;
    }
}
```

### Step 2: Test Translation Display

Create tests to verify that translations are displayed correctly:

```php
// tests/Feature/InternationalizationTest.php
<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;use old\TestCase;

class InternationalizationTest extends TestCase
{
    use RefreshDatabase;
    
    public function test_welcome_page_displays_correct_translation()
    {
        // Test English
        $response = $this->withLocale('en')->get('/');
        $response->assertSee('Welcome to our application');
        
        // Test Spanish
        $response = $this->withLocale('es')->get('/');
        $response->assertSee('Bienvenido a nuestra aplicación');
        
        // Test French
        $response = $this->withLocale('fr')->get('/');
        $response->assertSee('Bienvenue dans notre application');
    }
    
    public function test_login_page_displays_correct_translation()
    {
        // Test English
        $response = $this->withLocale('en')->get('/login');
        $response->assertSee('Log in to your account');
        $response->assertSee('Email address');
        $response->assertSee('Password');
        $response->assertSee('Remember me');
        
        // Test Spanish
        $response = $this->withLocale('es')->get('/login');
        $response->assertSee('Iniciar sesión en su cuenta');
        $response->assertSee('Dirección de correo electrónico');
        $response->assertSee('Contraseña');
        $response->assertSee('Recuérdame');
        
        // Test French
        $response = $this->withLocale('fr')->get('/login');
        $response->assertSee('Connectez-vous à votre compte');
        $response->assertSee('Adresse e-mail');
        $response->assertSee('Mot de passe');
        $response->assertSee('Se souvenir de moi');
    }
}
```

### Step 3: Test Locale Switching

Create tests to verify that locale switching works:

```php
// tests/Feature/InternationalizationTest.php
public function test_user_can_switch_locale()
{
    $user = User::factory()->create();
    
    // Test switching to Spanish
    $response = $this->actingAs($user)
        ->post('/locale', ['locale' => 'es']);
    
    $response->assertRedirect();
    $this->assertEquals('es', session('locale'));
    $this->assertEquals('es', $user->fresh()->locale);
    
    // Test switching to French
    $response = $this->actingAs($user)
        ->post('/locale', ['locale' => 'fr']);
    
    $response->assertRedirect();
    $this->assertEquals('fr', session('locale'));
    $this->assertEquals('fr', $user->fresh()->locale);
}

public function test_locale_is_detected_from_accept_language_header()
{
    // Test English
    $response = $this->withAcceptLanguage('en-US,en;q=0.9')
        ->get('/');
    
    $this->assertEquals('en', app()->getLocale());
    
    // Test Spanish
    $response = $this->withAcceptLanguage('es-ES,es;q=0.9')
        ->get('/');
    
    $this->assertEquals('es', app()->getLocale());
    
    // Test French
    $response = $this->withAcceptLanguage('fr-FR,fr;q=0.9')
        ->get('/');
    
    $this->assertEquals('fr', app()->getLocale());
}
```

### Step 4: Test Date and Time Formatting

Create tests to verify that date and time formatting is correct:

```php
// tests/Feature/InternationalizationTest.php
public function test_date_formatting_is_correct()
{
    $user = User::factory()->create();
    $post = Post::factory()->create([
        'user_id' => $user->id,
        'created_at' => '2023-01-15 12:30:45',
    ]);
    
    // Test English (US) date format
    $response = $this->withLocale('en')
        ->get("/posts/{$post->id}");
    
    $response->assertSee('January 15, 2023');
    
    // Test Spanish date format
    $response = $this->withLocale('es')
        ->get("/posts/{$post->id}");
    
    $response->assertSee('15 de enero de 2023');
    
    // Test French date format
    $response = $this->withLocale('fr')
        ->get("/posts/{$post->id}");
    
    $response->assertSee('15 janvier 2023');
}

public function test_time_formatting_is_correct()
{
    $user = User::factory()->create();
    $post = Post::factory()->create([
        'user_id' => $user->id,
        'created_at' => '2023-01-15 12:30:45',
    ]);
    
    // Test English (US) time format
    $response = $this->withLocale('en')
        ->get("/posts/{$post->id}");
    
    $response->assertSee('12:30 PM');
    
    // Test Spanish time format
    $response = $this->withLocale('es')
        ->get("/posts/{$post->id}");
    
    $response->assertSee('12:30');
    
    // Test French time format
    $response = $this->withLocale('fr')
        ->get("/posts/{$post->id}");
    
    $response->assertSee('12:30');
}
```

### Step 5: Test Number and Currency Formatting

Create tests to verify that number and currency formatting is correct:

```php
// tests/Feature/InternationalizationTest.php
public function test_number_formatting_is_correct()
{
    $user = User::factory()->create();
    $product = Product::factory()->create([
        'user_id' => $user->id,
        'price' => 1234.56,
    ]);
    
    // Test English (US) number format
    $response = $this->withLocale('en')
        ->get("/products/{$product->id}");
    
    $response->assertSee('1,234.56');
    
    // Test Spanish number format
    $response = $this->withLocale('es')
        ->get("/products/{$product->id}");
    
    $response->assertSee('1.234,56');
    
    // Test French number format
    $response = $this->withLocale('fr')
        ->get("/products/{$product->id}");
    
    $response->assertSee('1 234,56');
}

public function test_currency_formatting_is_correct()
{
    $user = User::factory()->create();
    $product = Product::factory()->create([
        'user_id' => $user->id,
        'price' => 1234.56,
    ]);
    
    // Test English (US) currency format
    $response = $this->withLocale('en')
        ->get("/products/{$product->id}");
    
    $response->assertSee('$1,234.56');
    
    // Test Spanish currency format
    $response = $this->withLocale('es')
        ->get("/products/{$product->id}");
    
    $response->assertSee('1.234,56 €');
    
    // Test French currency format
    $response = $this->withLocale('fr')
        ->get("/products/{$product->id}");
    
    $response->assertSee('1 234,56 €');
}
```

### Step 6: Test Pluralization

Create tests to verify that pluralization rules are applied correctly:

```php
// tests/Feature/InternationalizationTest.php
public function test_pluralization_is_correct()
{
    $user = User::factory()->create();
    
    // Create different numbers of posts
    $posts0 = [];
    $posts1 = [Post::factory()->create(['user_id' => $user->id])];
    $posts2 = [
        Post::factory()->create(['user_id' => $user->id]),
        Post::factory()->create(['user_id' => $user->id]),
    ];
    
    // Test English pluralization
    $this->withLocale('en');
    
    $this->assertEquals('No posts', trans_choice('messages.posts', 0));
    $this->assertEquals('1 post', trans_choice('messages.posts', 1));
    $this->assertEquals('2 posts', trans_choice('messages.posts', 2));
    
    // Test Spanish pluralization
    $this->withLocale('es');
    
    $this->assertEquals('No hay publicaciones', trans_choice('messages.posts', 0));
    $this->assertEquals('1 publicación', trans_choice('messages.posts', 1));
    $this->assertEquals('2 publicaciones', trans_choice('messages.posts', 2));
    
    // Test French pluralization
    $this->withLocale('fr');
    
    $this->assertEquals('Aucun article', trans_choice('messages.posts', 0));
    $this->assertEquals('1 article', trans_choice('messages.posts', 1));
    $this->assertEquals('2 articles', trans_choice('messages.posts', 2));
    
    // Test Russian pluralization
    $this->withLocale('ru');
    
    $this->assertEquals('Нет постов', trans_choice('messages.posts', 0));
    $this->assertEquals('1 пост', trans_choice('messages.posts', 1));
    $this->assertEquals('2 поста', trans_choice('messages.posts', 2));
    $this->assertEquals('5 постов', trans_choice('messages.posts', 5));
}
```

### Step 7: Test RTL Layout

Create tests to verify that RTL layout works:

```php
// tests/Feature/InternationalizationTest.php
public function test_rtl_layout_is_correct()
{
    // Test Arabic (RTL)
    $response = $this->withLocale('ar')
        ->get('/');
    
    $response->assertSee('dir="rtl"');
    
    // Test English (LTR)
    $response = $this->withLocale('en')
        ->get('/');
    
    $response->assertSee('dir="ltr"');
}
```

### Step 8: Test Cultural Adaptations

Create tests to verify that cultural adaptations work:

```php
// tests/Feature/InternationalizationTest.php
public function test_name_formatting_is_correct()
{
    $user = User::factory()->create([
        'first_name' => 'John',
        'last_name' => 'Smith',
    ]);
    
    // Test Western name format
    $this->withLocale('en');
    $this->assertEquals('John Smith', app(App\Helpers\NameHelper::class)->formatName($user->first_name, $user->last_name));
    
    // Test Eastern name format
    $this->withLocale('zh');
    $this->assertEquals('Smith John', app(App\Helpers\NameHelper::class)->formatName($user->first_name, $user->last_name));
}

public function test_address_formatting_is_correct()
{
    $address = [
        'name' => 'John Smith',
        'street' => '123 Main St',
        'city' => 'New York',
        'state' => 'NY',
        'postal_code' => '10001',
        'country' => 'US',
    ];
    
    // Test US address format
    $this->withLocale('en');
    $formattedAddress = app(App\Helpers\AddressHelper::class)->formatAddress($address);
    $this->assertStringContainsString('John Smith', $formattedAddress);
    $this->assertStringContainsString('123 Main St', $formattedAddress);
    $this->assertStringContainsString('New York, NY 10001', $formattedAddress);
    $this->assertStringContainsString('US', $formattedAddress);
    
    // Test Japanese address format
    $address['country'] = 'JP';
    $this->withLocale('ja');
    $formattedAddress = app(App\Helpers\AddressHelper::class)->formatAddress($address);
    $this->assertStringContainsString('JP', $formattedAddress);
    $this->assertStringContainsString('10001', $formattedAddress);
    $this->assertStringContainsString('NY', $formattedAddress);
    $this->assertStringContainsString('New York', $formattedAddress);
    $this->assertStringContainsString('123 Main St', $formattedAddress);
    $this->assertStringContainsString('John Smith', $formattedAddress);
}
```

### Step 9: Test Legal Compliance

Create tests to verify that legal requirements are met:

```php
// tests/Feature/InternationalizationTest.php
public function test_cookie_consent_is_displayed()
{
    // Test English
    $response = $this->withLocale('en')
        ->get('/');
    
    $response->assertSee('This website uses cookies');
    
    // Test Spanish
    $response = $this->withLocale('es')
        ->get('/');
    
    $response->assertSee('Este sitio web utiliza cookies');
    
    // Test French
    $response = $this->withLocale('fr')
        ->get('/');
    
    $response->assertSee('Ce site utilise des cookies');
}

public function test_gdpr_features_are_available()
{
    $user = User::factory()->create();
    
    // Test data export
    $response = $this->actingAs($user)
        ->get('/gdpr/export');
    
    $response->assertStatus(200);
    
    // Test data deletion
    $response = $this->actingAs($user)
        ->get('/gdpr/delete');
    
    $response->assertStatus(200);
}
```

### Step 10: Test Browser Compatibility

Create tests to verify that internationalization works in different browsers:

```php
// tests/Browser/InternationalizationTest.php
<?php

namespace Tests\Browser;

use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseMigrations;
use Laravel\Dusk\Browser;
use Tests\DuskTestCase;

class InternationalizationTest extends DuskTestCase
{
    use DatabaseMigrations;
    
    public function test_user_can_switch_language()
    {
        $user = User::factory()->create();
        
        $this->browse(function (Browser $browser) use ($user) {
            $browser->loginAs($user)
                ->visit('/')
                ->assertSee('Welcome to our application')
                ->click('@language-switcher')
                ->click('@language-es')
                ->assertSee('Bienvenido a nuestra aplicación')
                ->click('@language-switcher')
                ->click('@language-fr')
                ->assertSee('Bienvenue dans notre application');
        });
    }
    
    public function test_rtl_layout_works_in_browser()
    {
        $this->browse(function (Browser $browser) {
            $browser->visit('/')
                ->click('@language-switcher')
                ->click('@language-ar')
                ->assertAttribute('html', 'dir', 'rtl');
        });
    }
}
```

## Best Practices for Internationalization Testing

1. **Test with Real Data**: Use real translations and data for testing
2. **Test with Different Locales**: Test with a variety of locales, including RTL languages
3. **Test Edge Cases**: Test edge cases like empty strings, long strings, and special characters
4. **Test with Different Browsers**: Test with different browsers and devices
5. **Test with Different User Preferences**: Test with different user preferences and settings
6. **Test with Different Time Zones**: Test with different time zones
7. **Test with Different Regions**: Test with different regions and cultural settings
8. **Test with Different Legal Requirements**: Test with different legal requirements
9. **Automate Testing**: Automate internationalization testing as much as possible
10. **Include Internationalization in CI/CD**: Include internationalization testing in your CI/CD pipeline

## Verification

To verify that your internationalization testing is effective:

1. Run all tests and ensure they pass
2. Manually test the application in different languages
3. Test with users from different cultures and regions
4. Test with different browsers and devices
5. Test with different user preferences and settings

## Troubleshooting

### Missing Translations

If translations are missing:

1. Check that the translation files exist
2. Verify that the translation keys are correct
3. Check that the locale is set correctly
4. Use the `ScanMissingTranslations` command to find missing translations

### Incorrect Formatting

If formatting is incorrect:

1. Check that the locale is set correctly
2. Verify that the formatting functions are using the correct locale
3. Test with different locales to ensure consistent formatting

### RTL Layout Issues

If RTL layout is not working correctly:

1. Check that the `dir` attribute is set correctly
2. Verify that RTL-specific CSS is applied
3. Test with different RTL languages to ensure consistent layout

## Next Steps

Now that you've learned how to test internationalized applications, you have completed the Internationalization and Localization section of the UME tutorial. You can now apply these concepts to your own applications to make them accessible to users around the world.
