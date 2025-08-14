# Testing the Flags Enum

<link rel="stylesheet" href="../../assets/css/styles.css">

## Overview

The Flags enum is a crucial component of our HasAdditionalFeatures trait, providing a standardized way to define and validate boolean flags for our models. This document outlines how to test the Flags enum to ensure it works correctly.

## Test File

Create a new test file at `tests/Unit/Enums/FlagsTest.php`:

```php
<?php

namespace Tests\Unit\Enums;

use App\Enums\Flags;use old\TestCase;use PHPUnit\Framework\Attributes\Test;

class FlagsTest extends TestCase
{
    #[Test]
    public function it_has_expected_cases()
    {
        $expectedCases = [
            'FEATURED',
            'VERIFIED',
            'PREMIUM',
            'ARCHIVED',
            'PINNED',
            'SPONSORED',
            'BETA',
            'DEPRECATED',
            'HIDDEN',
            'READONLY',
        ];
        
        $actualCases = array_map(fn($case) => $case->name, Flags::cases());
        
        $this->assertEquals($expectedCases, $actualCases);
    }
    
    #[Test]
    public function it_has_string_values()
    {
        $expectedValues = [
            'featured',
            'verified',
            'premium',
            'archived',
            'pinned',
            'sponsored',
            'beta',
            'deprecated',
            'hidden',
            'readonly',
        ];
        
        $actualValues = array_map(fn($case) => $case->value, Flags::cases());
        
        $this->assertEquals($expectedValues, $actualValues);
    }
    
    #[Test]
    public function it_can_get_description()
    {
        $this->assertNotEmpty(Flags::FEATURED->description());
        $this->assertNotEmpty(Flags::VERIFIED->description());
        $this->assertNotEmpty(Flags::PREMIUM->description());
        
        // Check a specific description
        $this->assertEquals(
            'Featured item that should be highlighted in listings',
            Flags::FEATURED->description()
        );
    }
    
    #[Test]
    public function it_can_get_icon()
    {
        $this->assertNotEmpty(Flags::FEATURED->icon());
        $this->assertNotEmpty(Flags::VERIFIED->icon());
        $this->assertNotEmpty(Flags::PREMIUM->icon());
        
        // Check a specific icon
        $this->assertEquals('star', Flags::FEATURED->icon());
    }
    
    #[Test]
    public function it_can_get_color()
    {
        $this->assertNotEmpty(Flags::FEATURED->color());
        $this->assertNotEmpty(Flags::VERIFIED->color());
        $this->assertNotEmpty(Flags::PREMIUM->color());
        
        // Check a specific color
        $this->assertEquals('yellow', Flags::FEATURED->color());
    }
    
    #[Test]
    public function it_can_convert_to_array()
    {
        $array = Flags::toArray();
        
        $this->assertIsArray($array);
        $this->assertContains('featured', $array);
        $this->assertContains('verified', $array);
        $this->assertContains('premium', $array);
    }
    
    #[Test]
    public function it_can_convert_to_select_array()
    {
        $selectArray = Flags::toSelectArray();
        
        $this->assertIsArray($selectArray);
        $this->assertArrayHasKey('featured', $selectArray);
        $this->assertArrayHasKey('verified', $selectArray);
        $this->assertArrayHasKey('premium', $selectArray);
        
        // Check that values are descriptions
        $this->assertEquals(
            'Featured item that should be highlighted in listings',
            $selectArray['featured']
        );
    }
}
```

## Integration with HasAdditionalFeatures

To test the integration between the Flags enum and the HasAdditionalFeatures trait, we can add the following test to our HasAdditionalFeaturesTraitTest:

```php
#[Test]
public function it_validates_flags_against_enum()
{
    $user = User::factory()->create();
    
    // This should work fine
    $user->flag(Flags::VERIFIED->value);
    
    // This should throw an exception
    $this->expectException(\InvalidArgumentException::class);
    $user->flag('invalid_flag');
}
```

## Running the Tests

To run the Flags enum tests, use the following command:

```bash
php artisan test --filter=FlagsTest
```

To run all tests including the Flags tests, use:

```bash
php artisan test
```

## Expected Output

When running the Flags tests, you should see output similar to:

```
PASS  Tests\Unit\Enums\FlagsTest
✓ it has expected cases
✓ it has string values
✓ it can get description
✓ it can get icon
✓ it can get color
✓ it can convert to array
✓ it can convert to select array

Tests:  7 passed
Time:   0.12s
```

This confirms that the Flags enum is working correctly and can be used with the HasAdditionalFeatures trait.
