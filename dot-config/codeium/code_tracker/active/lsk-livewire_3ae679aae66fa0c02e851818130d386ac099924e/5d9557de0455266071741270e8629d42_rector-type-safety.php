�<?php

declare(strict_types=1);

use Rector\Config\RectorConfig;
use Rector\TypeDeclaration\Rector\ClassMethod\AddReturnTypeDeclarationRector;
use Rector\TypeDeclaration\Rector\ClassMethod\AddVoidReturnTypeWhereNoReturnRector;
use Rector\TypeDeclaration\Rector\ClassMethod\ReturnTypeFromStrictNativeCallRector;
use Rector\TypeDeclaration\Rector\Property\AddPropertyTypeDeclarationRector;
use Rector\TypeDeclaration\Rector\Property\TypedPropertyFromStrictConstructorRector;

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

    // Type Declaration rules
    $rectorConfig->rules([
        // Add return types to methods
        AddReturnTypeDeclarationRector::class,
        AddVoidReturnTypeWhereNoReturnRector::class,
        ReturnTypeFromStrictNativeCallRector::class,

        // Add property types
        AddPropertyTypeDeclarationRector::class,
        TypedPropertyFromStrictConstructorRector::class,
    ]);
};
� ��
�� ��
�� ��
�� ��
�� ��
�� ��
�� ��
��
 �
�
�� 
�� ��
�� 
�� ��
�� ��
�� ��
�� ��
�� ��
�� ��
�� ��
�� ��
�� ��
�� 
�� 
�� 
�� 
�� "(3ae679aae66fa0c02e851818130d386ac099924e2<file:///Users/s-a-c/Herd/lsk-livewire/rector-type-safety.php:%file:///Users/s-a-c/Herd/lsk-livewire