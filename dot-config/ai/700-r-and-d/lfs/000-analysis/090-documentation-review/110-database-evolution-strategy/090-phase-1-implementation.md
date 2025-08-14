# Phase 1 Implementation Plan: SQLite Enhancement for libSQL Compatibility

**Document ID:** DB-EVOLUTION-090  
**Version:** 1.0  
**Date:** June 1, 2025  
**Target Timeline:** 8 weeks  
**Confidence:** 90%

## Overview

This document provides actionable implementation tasks for **Phase 1** of our database evolution strategy, focusing on enhancing our current SQLite implementation with global scope patterns and monitoring that prepare for seamless libSQL migration.

## Phase 1 Goals

### Primary Objectives
1. **Enhanced Global Scope Patterns** - Implement cross-platform compatible global scope patterns
2. **Automated Monitoring Framework** - Deploy decision framework with migration triggers  
3. **libSQL Migration Readiness** - Prepare codebase for seamless libSQL transition
4. **Performance Baseline** - Establish performance benchmarks for comparison

### Success Criteria
- [ ] Global scope patterns compatible with libSQL implemented
- [ ] Automated decision monitoring framework deployed
- [ ] 99%+ code compatibility with libSQL validated
- [ ] Performance benchmarks established for all global scope queries
- [ ] Migration trigger thresholds configured and tested

## Implementation Timeline

### Week 1-2: Enhanced Global Scope Implementation

#### Task 1.1: Create Enhanced Global Scope Base Classes
**Estimated Time:** 3 days  
**Priority:** High  
**Files to Create/Modify:**
- `app/Models/Concerns/EnhancedGlobalScope.php`
- `app/Models/Concerns/ScopeAwareModel.php`
- Update existing models to use enhanced patterns

```php
// app/Models/Concerns/EnhancedGlobalScope.php
<?php

namespace App\Models\Concerns;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Scope;

class EnhancedGlobalScope implements Scope
{
    public function apply(Builder $builder, Model $model)
    {
        $user = auth()->user();
        
        // Base tenant isolation (compatible across all platforms)
        $builder->where(function ($query) use ($user, $model) {
            $query->where($model->getTable() . '.tenant_id', $user?->tenant_id ?? app('tenant.current'));
            
            // Enhanced global scope patterns (libSQL-optimized)
            if ($user?->hasGlobalAccess()) {
                $query->orWhere(function ($globalQuery) use ($user, $model) {
                    $globalQuery->where($model->getTable() . '.is_global', true)
                               ->where($model->getTable() . '.access_level', '<=', $user->access_level ?? 0);
                    
                    // Regional scoping (prepared for libSQL regional distribution)
                    if ($user->region ?? null) {
                        $globalQuery->where(function ($regionQuery) use ($user, $model) {
                            $regionQuery->where($model->getTable() . '.region', $user->region)
                                       ->orWhere($model->getTable() . '.region', 'global');
                        });
                    }
                });
            }
        });
    }
}
```

#### Task 1.2: Database Schema Enhancements  
**Estimated Time:** 2 days  
**Priority:** High

Create migration for global scope support:

```php
// database/migrations/add_global_scope_columns.php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        // Add global scope columns to existing tables
        $tables = ['users', 'projects', 'documents']; // Adjust based on your models
        
        foreach ($tables as $table) {
            if (Schema::hasTable($table)) {
                Schema::table($table, function (Blueprint $table) {
                    if (!Schema::hasColumn($table->getTable(), 'tenant_id')) {
                        $table->uuid('tenant_id')->nullable()->index();
                    }
                    if (!Schema::hasColumn($table->getTable(), 'is_global')) {
                        $table->boolean('is_global')->default(false)->index();
                    }
                    if (!Schema::hasColumn($table->getTable(), 'access_level')) {
                        $table->integer('access_level')->default(0)->index();
                    }
                    if (!Schema::hasColumn($table->getTable(), 'region')) {
                        $table->string('region', 20)->default('global')->index();
                    }
                    
                    // libSQL-optimized composite index
                    $table->index(['tenant_id', 'is_global', 'region', 'access_level'], 'global_scope_idx');
                });
            }
        }
    }
    
    public function down()
    {
        $tables = ['users', 'projects', 'documents'];
        
        foreach ($tables as $table) {
            if (Schema::hasTable($table)) {
                Schema::table($table, function (Blueprint $table) {
                    $table->dropIndex('global_scope_idx');
                    $table->dropColumn(['tenant_id', 'is_global', 'access_level', 'region']);
                });
            }
        }
    }
};
```

### Week 3-4: Automated Monitoring Framework

#### Task 2.1: Database Decision Engine
**Estimated Time:** 4 days  
**Priority:** High

```php
// app/Services/DatabaseDecisionEngine.php
<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Cache;

class DatabaseDecisionEngine
{
    public function evaluateMigrationNeed(): array
    {
        $metrics = $this->collectMetrics();
        $recommendations = [];
        
        // libSQL migration triggers
        if ($this->shouldMigrateToLibSQL($metrics)) {
            $recommendations[] = [
                'action' => 'migrate_to_libsql',
                'confidence' => 85,
                'reason' => $this->getLibSQLMigrationReason($metrics),
                'timeframe' => '2-4 weeks',
                'metrics' => $metrics
            ];
        }
        
        // PostgreSQL migration triggers  
        if ($this->shouldMigrateToPostgreSQL($metrics)) {
            $recommendations[] = [
                'action' => 'migrate_to_postgresql',
                'confidence' => 92,
                'reason' => $this->getPostgreSQLMigrationReason($metrics),
                'timeframe' => '6-8 weeks',
                'metrics' => $metrics
            ];
        }
        
        return $recommendations;
    }
    
    protected function collectMetrics(): array
    {
        return [
            'tenant_count' => $this->getTenantCount(),
            'database_size' => $this->getDatabaseSize(),
            'global_data_size' => $this->getGlobalDataSize(),
            'avg_query_time' => $this->getAverageQueryTime(),
            'concurrent_queries' => $this->getConcurrentQueryCount(),
            'scope_complexity' => $this->getScopeComplexity(),
            'security_incidents' => $this->getSecurityIncidentCount(),
        ];
    }
    
    protected function shouldMigrateToLibSQL(array $metrics): bool
    {
        return $metrics['global_data_size'] > 100 * 1024 * 1024 || // 100MB
               $metrics['scope_complexity'] > 3 ||
               $metrics['avg_query_time'] > 200 || // 200ms
               $metrics['tenant_count'] > 50;
    }
    
    protected function shouldMigrateToPostgreSQL(array $metrics): bool
    {
        return $metrics['security_incidents'] > 0 ||
               $metrics['tenant_count'] > 500 ||
               $metrics['global_data_size'] > 1024 * 1024 * 1024 || // 1GB
               $metrics['concurrent_queries'] > 100;
    }
}
```

#### Task 2.2: Performance Monitoring Service
**Estimated Time:** 3 days  
**Priority:** Medium

```php
// app/Services/DatabasePerformanceMonitor.php
<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class DatabasePerformanceMonitor
{
    protected array $queryLog = [];
    
    public function startMonitoring(): void
    {
        DB::listen(function ($query) {
            $this->logQuery($query);
            $this->analyzeGlobalScopePerformance($query);
        });
    }
    
    protected function logQuery($query): void
    {
        $this->queryLog[] = [
            'sql' => $query->sql,
            'bindings' => $query->bindings,
            'time' => $query->time,
            'timestamp' => now(),
            'has_global_scope' => $this->hasGlobalScopePattern($query->sql),
            'tenant_isolated' => $this->isTenantIsolated($query->sql),
        ];
        
        // Log slow queries
        if ($query->time > 200) { // 200ms threshold
            Log::warning('Slow query detected', [
                'sql' => $query->sql,
                'time' => $query->time,
                'bindings' => $query->bindings,
            ]);
        }
    }
    
    protected function analyzeGlobalScopePerformance($query): void
    {
        if ($this->hasGlobalScopePattern($query->sql)) {
            Cache::remember('global_scope_performance', 3600, function () {
                return [];
            });
            
            $performance = Cache::get('global_scope_performance', []);
            $performance[] = [
                'time' => $query->time,
                'timestamp' => now(),
            ];
            
            // Keep only last 100 queries
            if (count($performance) > 100) {
                $performance = array_slice($performance, -100);
            }
            
            Cache::put('global_scope_performance', $performance, 3600);
        }
    }
    
    public function getGlobalScopeStats(): array
    {
        $performance = Cache::get('global_scope_performance', []);
        
        if (empty($performance)) {
            return ['avg_time' => 0, 'query_count' => 0];
        }
        
        $times = array_column($performance, 'time');
        
        return [
            'avg_time' => array_sum($times) / count($times),
            'max_time' => max($times),
            'min_time' => min($times),
            'query_count' => count($performance),
            'p95_time' => $this->calculatePercentile($times, 95),
        ];
    }
}
```

### Week 5-6: libSQL Preparation

#### Task 3.1: libSQL Development Environment Setup
**Estimated Time:** 2 days  
**Priority:** Medium

```bash
# Install libSQL CLI (for testing)
brew install tursodatabase/tap/turso

# Create test libSQL database
turso db create lfs-test-db

# Get connection string for testing
turso db show lfs-test-db --url
```

#### Task 3.2: Database Configuration Enhancement
**Estimated Time:** 2 days  
**Priority:** Medium

```php
// config/database.php enhancement
'connections' => [
    'sqlite' => [
        'driver' => 'sqlite',
        'url' => env('DATABASE_URL'),
        'database' => env('DB_DATABASE', database_path('database.sqlite')),
        'prefix' => '',
        'foreign_key_constraints' => env('DB_FOREIGN_KEYS', true),
        // Enhanced for libSQL compatibility
        'options' => [
            PDO::ATTR_TIMEOUT => 30,
            PDO::ATTR_EMULATE_PREPARES => false,
        ],
    ],
    
    // Prepare libSQL configuration
    'libsql' => [
        'driver' => 'sqlite', // Compatible driver
        'url' => env('LIBSQL_DATABASE_URL'),
        'database' => env('LIBSQL_DATABASE_PATH', ':memory:'),
        'prefix' => '',
        'foreign_key_constraints' => true,
        'options' => [
            PDO::ATTR_TIMEOUT => 30,
            PDO::ATTR_EMULATE_PREPARES => false,
        ],
    ],
];
```

### Week 7-8: Testing & Validation

#### Task 4.1: Global Scope Testing Framework
**Estimated Time:** 3 days  
**Priority:** High

```php
// tests/Feature/GlobalScopeTest.php
<?php

namespace Tests\Feature;

use App\Models\User;use Illuminate\Foundation\Testing\RefreshDatabase;use old\TestCase;

class GlobalScopeTest extends TestCase
{
    use RefreshDatabase;
    
    public function test_tenant_isolation_prevents_cross_tenant_access()
    {
        $tenant1 = 'tenant-1';
        $tenant2 = 'tenant-2';
        
        // Create users in different tenants
        $user1 = User::factory()->create(['tenant_id' => $tenant1]);
        $user2 = User::factory()->create(['tenant_id' => $tenant2]);
        
        // Act as tenant 1 user
        $this->actingAs($user1);
        app()->instance('tenant.current', $tenant1);
        
        // Should only see tenant 1 users
        $users = User::all();
        
        $this->assertEquals(1, $users->count());
        $this->assertEquals($tenant1, $users->first()->tenant_id);
    }
    
    public function test_global_data_access_with_proper_permissions()
    {
        $tenant1 = 'tenant-1';
        
        // Create tenant user with global access
        $user = User::factory()->create([
            'tenant_id' => $tenant1,
            'access_level' => 5,
            'has_global_access' => true,
        ]);
        
        // Create global data
        $globalUser = User::factory()->create([
            'tenant_id' => 'global',
            'is_global' => true,
            'access_level' => 3,
        ]);
        
        $this->actingAs($user);
        app()->instance('tenant.current', $tenant1);
        
        $users = User::all();
        
        // Should see both tenant and global users
        $this->assertEquals(2, $users->count());
        $this->assertTrue($users->contains('tenant_id', $tenant1));
        $this->assertTrue($users->contains('is_global', true));
    }
    
    public function test_libsql_compatibility_patterns()
    {
        // Test that our global scope patterns work with libSQL-style queries
        $this->markTestSkipped('Requires libSQL test database setup');
        
        // Switch to libSQL connection for testing
        config(['database.default' => 'libsql']);
        
        // Run same tenant isolation tests
        $this->test_tenant_isolation_prevents_cross_tenant_access();
        $this->test_global_data_access_with_proper_permissions();
    }
}
```

#### Task 4.2: Migration Trigger Testing
**Estimated Time:** 2 days  
**Priority:** Medium

```php
// tests/Unit/DatabaseDecisionEngineTest.php
<?php

namespace Tests\Unit;

use App\Services\DatabaseDecisionEngine;use Illuminate\Foundation\Testing\RefreshDatabase;use old\TestCase;

class DatabaseDecisionEngineTest extends TestCase
{
    use RefreshDatabase;
    
    public function test_libsql_migration_trigger_on_data_size()
    {
        $engine = new DatabaseDecisionEngine();
        
        // Mock large global data size
        $this->mockMetrics([
            'global_data_size' => 150 * 1024 * 1024, // 150MB
            'tenant_count' => 30,
            'scope_complexity' => 2,
            'avg_query_time' => 150,
        ]);
        
        $recommendations = $engine->evaluateMigrationNeed();
        
        $this->assertCount(1, $recommendations);
        $this->assertEquals('migrate_to_libsql', $recommendations[0]['action']);
        $this->assertEquals(85, $recommendations[0]['confidence']);
    }
    
    public function test_postgresql_migration_trigger_on_tenant_count()
    {
        $engine = new DatabaseDecisionEngine();
        
        // Mock high tenant count
        $this->mockMetrics([
            'tenant_count' => 600,
            'security_incidents' => 0,
            'global_data_size' => 500 * 1024 * 1024,
        ]);
        
        $recommendations = $engine->evaluateMigrationNeed();
        
        $this->assertCount(1, $recommendations);
        $this->assertEquals('migrate_to_postgresql', $recommendations[0]['action']);
        $this->assertEquals(92, $recommendations[0]['confidence']);
    }
    
    protected function mockMetrics(array $overrides = []): void
    {
        $defaults = [
            'tenant_count' => 10,
            'database_size' => 50 * 1024 * 1024,
            'global_data_size' => 10 * 1024 * 1024,
            'avg_query_time' => 50,
            'concurrent_queries' => 10,
            'scope_complexity' => 1,
            'security_incidents' => 0,
        ];
        
        $metrics = array_merge($defaults, $overrides);
        
        // Mock the DatabaseDecisionEngine methods
        // Implementation would depend on your testing strategy
    }
}
```

## Deployment Checklist

### Week 1-2 Deliverables
- [ ] Enhanced global scope classes implemented
- [ ] Database schema migration created and tested
- [ ] Existing models updated to use enhanced patterns
- [ ] Unit tests for global scope functionality

### Week 3-4 Deliverables  
- [ ] Database decision engine service implemented
- [ ] Performance monitoring service deployed
- [ ] Automated migration trigger alerts configured
- [ ] Monitoring dashboard created (optional)

### Week 5-6 Deliverables
- [ ] libSQL development environment configured
- [ ] Database configuration enhanced for multi-platform support
- [ ] Migration compatibility validation framework

### Week 7-8 Deliverables
- [ ] Comprehensive test suite for global scope patterns
- [ ] Migration trigger testing validated
- [ ] Performance baseline established
- [ ] libSQL migration readiness assessment completed

## Risk Mitigation

### Technical Risks
1. **Breaking Changes**: All changes maintain backward compatibility
2. **Performance Impact**: Monitoring ensures no performance regression
3. **Testing Coverage**: Comprehensive test suite validates all scenarios

### Migration Risks
1. **Data Safety**: All migrations are reversible
2. **Downtime**: Changes applied during low-traffic periods
3. **Validation**: Automated testing ensures data integrity

## Success Metrics

### Performance Benchmarks (Week 8)
- [ ] Global scope query performance baseline established
- [ ] Concurrent access patterns measured
- [ ] Resource usage metrics documented

### Compatibility Validation (Week 8)
- [ ] 99%+ libSQL compatibility confirmed
- [ ] Global scope patterns work across platforms
- [ ] Migration trigger thresholds validated

### Code Quality (Ongoing)
- [ ] 90%+ test coverage for global scope functionality
- [ ] Zero security vulnerabilities in tenant isolation
- [ ] Documentation complete for all new patterns

---

**Next Phase**: Upon completion, proceed to [Phase 2: libSQL Transition Planning](./095-phase-2-planning.md)
