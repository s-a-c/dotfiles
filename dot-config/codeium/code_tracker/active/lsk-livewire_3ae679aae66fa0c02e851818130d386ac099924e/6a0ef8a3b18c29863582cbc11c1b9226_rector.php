ç<?php

declare(strict_types=1);

use Rector\CodeQuality\Rector\Class_\InlineConstructorDefaultToPropertyRector;
use Rector\Config\RectorConfig;
use Rector\DeadCode\Rector\ClassMethod\RemoveUselessParamTagRector;
use Rector\Naming\Rector\Assign\RenameVariableToMatchMethodCallReturnTypeRector;
use Rector\Set\ValueObject\LevelSetList;
use Rector\Set\ValueObject\SetList;
use Rector\TypeDeclaration\Rector\ClassMethod\AddReturnTypeDeclarationRector;
use Rector\TypeDeclaration\Rector\ClassMethod\AddVoidReturnTypeWhereNoReturnRector;
use Rector\TypeDeclaration\Rector\ClassMethod\ReturnTypeFromStrictNativeCallRector;
use Rector\TypeDeclaration\Rector\Property\AddPropertyTypeDeclarationRector;
use Rector\TypeDeclaration\Rector\Property\TypedPropertyFromStrictConstructorRector;
use RectorLaravel\Set\LaravelSetList;

return static function (RectorConfig $rectorConfig): void {
    // Standardized paths across all tools
    $rectorConfig->paths([
        __DIR__.'/app',
        __DIR__.'/bin',
        __DIR__.'/bootstrap',
        __DIR__.'/config',
        __DIR__.'/database',
        __DIR__.'/routes',
        __DIR__.'/tests',
        __DIR__.'/resources',
        __DIR__.'/packages/s-a-c/ai-prompt-addenda/src',
        __DIR__.'/packages/s-a-c/ai-prompt-addenda/tests',
    ]);

    // Standardized exclude paths across all tools
    $rectorConfig->skip([
        __DIR__.'/vendor',
        __DIR__.'/vendor/*',
        __DIR__.'/vendor/**/*',
        __DIR__.'/node_modules',
        __DIR__.'/storage',
        __DIR__.'/bootstrap/cache',
        __DIR__.'/public',
        // Skip migration files to avoid breaking changes to schema definitions
        __DIR__.'/database/migrations',
        // Skip rector cache files to avoid processing them
        __DIR__.'/reports/rector/cache',
    ]);

    // Output directory for reports
    $rectorConfig->cacheDirectory('reports/rector/cache');

    // Performance settings
    // Parallel processing - standardized across tools
    $rectorConfig->parallel(8); // Aligned with other tools
    $rectorConfig->memoryLimit('1G'); // Standardized memory limit
    // Increase timeout for parallel processing
    $rectorConfig->fileExtensions(['php']);

    // PHP version features - update to PHP 8.4
    $rectorConfig->phpVersion(80400); // Explicitly set PHP version to 8.4

    $rectorConfig->sets([
        LevelSetList::UP_TO_PHP_84, // Update to target PHP 8.4
        SetList::CODE_QUALITY,
        SetList::CODING_STYLE,
        SetList::DEAD_CODE,
        SetList::EARLY_RETURN,
        SetList::NAMING,
        SetList::PRIVATIZATION,
        SetList::TYPE_DECLARATION,
        // Laravel specific rulesets
        LaravelSetList::LARAVEL_CODE_QUALITY,
        LaravelSetList::LARAVEL_ARRAY_STR_FUNCTION_TO_STATIC_CALL,
    ]);

    // Specific rules for type safety and code quality
    $rectorConfig->rules([
        // Add return types to methods
        AddReturnTypeDeclarationRector::class,
        AddVoidReturnTypeWhereNoReturnRector::class,
        ReturnTypeFromStrictNativeCallRector::class,
        // Add property types
        AddPropertyTypeDeclarationRector::class,
        TypedPropertyFromStrictConstructorRector::class,

        InlineConstructorDefaultToPropertyRector::class,
        RemoveUselessParamTagRector::class,
        RenameVariableToMatchMethodCallReturnTypeRector::class,
        // Custom rules
        App\Rules\Rector\UseEnumInsteadOfConstantsRector::class,
    ]);
};
<<<<<<< HEAD
¶
 ¶
ã
=======
¶ ¶ã
>>>>>>> origin/develop
ãè 
èî 
îÔ Ô
Ù 
Ùê 
êî 
îß 
ßü üÌ
<<<<<<< HEAD
Ìç "(3ae679aae66fa0c02e851818130d386ac099924e20file:///Users/s-a-c/Herd/lsk-livewire/rector.php:%file:///Users/s-a-c/Herd/lsk-livewire
=======
Ìç "(3ae679aae66fa0c02e851818130d386ac099924e20file:///Users/s-a-c/Herd/lsk-livewire/rector.php:%file:///Users/s-a-c/Herd/lsk-livewire
>>>>>>> origin/develop
