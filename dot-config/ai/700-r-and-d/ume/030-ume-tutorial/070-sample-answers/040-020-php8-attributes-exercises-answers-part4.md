# PHP 8 Attributes Exercises - Sample Answers (Part 4)

<link rel="stylesheet" href="../assets/css/styles.css">

This file contains sample answers for the fourth set of PHP 8 attributes exercises. For additional parts, see the related files.

## Set 4: Attribute-Based Testing

### Question Answers

1. **What is the purpose of using PHP 8 attributes for testing?**
   - **Answer: C) To mark test methods and define their properties using native language features**
   - Explanation: PHP 8 attributes provide a native way to mark test methods and define their properties, replacing PHPDoc annotations with a more type-safe approach.

2. **Which attribute is used to mark a method as a test in PHPUnit 10+?**
   - **Answer: A) `#[Test]`**
   - Explanation: In PHPUnit 10+, the `#[Test]` attribute is used to mark a method as a test, replacing the PHPDoc `@test` annotation.

3. **How do you specify that a test depends on another test using attributes?**
   - **Answer: B) `#[Depends('testMethod')]`**
   - Explanation: The `#[Depends('testMethod')]` attribute is used to specify that a test depends on another test, replacing the PHPDoc `@depends` annotation.

4. **Which attribute is used to specify a data provider for a test?**
   - **Answer: C) `#[DataProvider('providerMethod')]`**
   - Explanation: The `#[DataProvider('providerMethod')]` attribute is used to specify a data provider for a test, replacing the PHPDoc `@dataProvider` annotation.

5. **What is the attribute for specifying which class is covered by a test?**
   - **Answer: B) `#[CoversClass(MyClass::class)]`**
   - Explanation: The `#[CoversClass(MyClass::class)]` attribute is used to specify which class is covered by a test, replacing the PHPDoc `@covers` annotation.

### Exercise: Create a test class using PHP 8 attributes

Here's a sample implementation of a test class for a `Calculator` class using PHP 8 attributes:

First, let's create a simple Calculator class:

```php
<?php

namespace App\Services;

class Calculator
{
    /**
     * Add two numbers.
     *
     * @param float $a
     * @param float $b
     * @return float
     */
    public function add(float $a, float $b): float
    {
        return $a + $b;
    }

    /**
     * Subtract two numbers.
     *
     * @param float $a
     * @param float $b
     * @return float
     */
    public function subtract(float $a, float $b): float
    {
        return $a - $b;
    }

    /**
     * Multiply two numbers.
     *
     * @param float $a
     * @param float $b
     * @return float
     */
    public function multiply(float $a, float $b): float
    {
        return $a * $b;
    }

    /**
     * Divide two numbers.
     *
     * @param float $a
     * @param float $b
     * @return float
     * @throws \InvalidArgumentException
     */
    public function divide(float $a, float $b): float
    {
        if ($b === 0.0) {
            throw new \InvalidArgumentException('Division by zero is not allowed');
        }

        return $a / $b;
    }
}
```

Now, let's create a test class for the Calculator class using PHP 8 attributes:

```php
<?php

namespace Tests\Unit\Services;

use App\Services\Calculator;
use InvalidArgumentException;
use PHPUnit\Framework\Attributes\CoversClass;
use PHPUnit\Framework\Attributes\DataProvider;
use PHPUnit\Framework\Attributes\Depends;
use PHPUnit\Framework\Attributes\Group;
use PHPUnit\Framework\Attributes\Test;
use PHPUnit\Framework\TestCase;

#[CoversClass(Calculator::class)]
class CalculatorTest extends TestCase
{
    private Calculator $calculator;

    protected function setUp(): void
    {
        parent::setUp();
        $this->calculator = new Calculator();
    }

    #[Test]
    #[Group('basic')]
    public function it_can_add_two_numbers()
    {
        $result = $this->calculator->add(2, 3);
        $this->assertEquals(5, $result);
        return $this->calculator;
    }

    #[Test]
    #[Group('basic')]
    public function it_can_subtract_two_numbers()
    {
        $result = $this->calculator->subtract(5, 3);
        $this->assertEquals(2, $result);
    }

    #[Test]
    #[Group('basic')]
    #[Depends('it_can_add_two_numbers')]
    public function it_can_multiply_two_numbers(Calculator $calculator)
    {
        $result = $calculator->multiply(2, 3);
        $this->assertEquals(6, $result);
    }

    #[Test]
    #[Group('basic')]
    public function it_can_divide_two_numbers()
    {
        $result = $this->calculator->divide(6, 3);
        $this->assertEquals(2, $result);
    }

    #[Test]
    #[Group('error-handling')]
    public function it_throws_exception_when_dividing_by_zero()
    {
        $this->expectException(InvalidArgumentException::class);
        $this->calculator->divide(6, 0);
    }

    #[Test]
    #[Group('calculations')]
    #[DataProvider('calculationProvider')]
    public function it_performs_calculations_correctly(string $operation, float $a, float $b, float $expected)
    {
        $result = match ($operation) {
            'add' => $this->calculator->add($a, $b),
            'subtract' => $this->calculator->subtract($a, $b),
            'multiply' => $this->calculator->multiply($a, $b),
            'divide' => $this->calculator->divide($a, $b),
            default => throw new \InvalidArgumentException('Invalid operation'),
        };

        $this->assertEquals($expected, $result);
    }

    public static function calculationProvider(): array
    {
        return [
            'addition' => ['add', 2, 3, 5],
            'subtraction' => ['subtract', 5, 3, 2],
            'multiplication' => ['multiply', 2, 3, 6],
            'division' => ['divide', 6, 3, 2],
            'negative numbers' => ['add', -2, -3, -5],
            'decimal numbers' => ['multiply', 2.5, 2, 5],
        ];
    }
}
```

This implementation demonstrates:

1. **Class-level attributes**:
   - `#[CoversClass(Calculator::class)]`: Specifies that this test class covers the Calculator class

2. **Method-level attributes**:
   - `#[Test]`: Marks a method as a test
   - `#[Group('basic')]`: Groups related tests together
   - `#[Depends('it_can_add_two_numbers')]`: Specifies that a test depends on another test
   - `#[DataProvider('calculationProvider')]`: Specifies a data provider for a test

3. **Data provider method**:
   - Provides multiple sets of test data for the `it_performs_calculations_correctly` test

The benefits of using PHP 8 attributes for testing include:

1. **Type safety**: Attributes are validated at compile time, catching errors early
2. **IDE support**: Better autocompletion and validation in modern IDEs
3. **Standardization**: A consistent, language-level feature rather than a documentation convention
4. **Refactoring support**: IDEs can refactor attributes more reliably than PHPDoc annotations
5. **Cleaner code**: Attributes are more concise and readable than PHPDoc annotations

Compared to PHPDoc annotations, PHP 8 attributes provide a more robust and type-safe way to define test methods and their properties. They are also more concise and easier to read, making the test code more maintainable.
