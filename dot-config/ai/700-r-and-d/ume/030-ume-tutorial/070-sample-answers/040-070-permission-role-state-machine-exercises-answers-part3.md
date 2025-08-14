# Permission/Role State Machine Exercises - Sample Answers (Part 3)

<link rel="stylesheet" href="../../../assets/css/styles.css">

## Exercise 2: Extending the Role State Machine (continued)

### Step 4: Create the SuspendRoleTransition class

```php
<?php

declare(strict_types=1);

namespace App\States\Role\Transitions;

use App\Models\URole;
use App\Models\User;
use App\States\Role\Active;
use App\States\Role\Suspended;
use Illuminate\Support\Facades\Log;
use Spatie\ModelStates\Transition;

/**
 * Transition from Active to Suspended when a role is suspended due to a security incident.
 */
class SuspendRoleTransition extends Transition
{
    /**
     * Constructor.
     */
    public function __construct(
        private ?User $suspendedBy = null,
        private string $reason,
        private ?string $incidentId = null,
        private ?string $notes = null
    ) {}

    /**
     * Handle the transition.
     */
    public function handle(URole $role, Active $currentState): Suspended
    {
        // Log the transition
        Log::info("Role {$role->id} ({$role->name}) was suspended by " . 
            ($this->suspendedBy ? "User {$this->suspendedBy->id}" : "system") . 
            " for reason: {$this->reason}" .
            ($this->incidentId ? " (Incident ID: {$this->incidentId})" : "") .
            ($this->notes ? " with notes: {$this->notes}" : ""));

        // Record the suspension in activity log
        activity()
            ->performedOn($role)
            ->causedBy($this->suspendedBy ?? auth()->user())
            ->withProperties([
                'reason' => $this->reason,
                'incident_id' => $this->incidentId,
                'notes' => $this->notes,
                'from_state' => 'active',
                'to_state' => 'suspended',
            ])
            ->log('role_suspended');

        // Notify security team
        // ... notification logic here ...

        // Return the new state
        return new Suspended($role);
    }
}
```

### Step 5: Create the ReinstateRoleTransition class

```php
<?php

declare(strict_types=1);

namespace App\States\Role\Transitions;

use App\Models\URole;
use App\Models\User;
use App\States\Role\Active;
use App\States\Role\Suspended;
use Illuminate\Support\Facades\Log;
use Spatie\ModelStates\Transition;

/**
 * Transition from Suspended to Active when a role is reinstated after a security incident.
 */
class ReinstateRoleTransition extends Transition
{
    /**
     * Constructor.
     */
    public function __construct(
        private ?User $reinstatedBy = null,
        private string $reason,
        private ?string $incidentResolutionId = null,
        private ?string $notes = null
    ) {}

    /**
     * Handle the transition.
     */
    public function handle(URole $role, Suspended $currentState): Active
    {
        // Log the transition
        Log::info("Role {$role->id} ({$role->name}) was reinstated by " . 
            ($this->reinstatedBy ? "User {$this->reinstatedBy->id}" : "system") . 
            " for reason: {$this->reason}" .
            ($this->incidentResolutionId ? " (Incident Resolution ID: {$this->incidentResolutionId})" : "") .
            ($this->notes ? " with notes: {$this->notes}" : ""));

        // Record the reinstatement in activity log
        activity()
            ->performedOn($role)
            ->causedBy($this->reinstatedBy ?? auth()->user())
            ->withProperties([
                'reason' => $this->reason,
                'incident_resolution_id' => $this->incidentResolutionId,
                'notes' => $this->notes,
                'from_state' => 'suspended',
                'to_state' => 'active',
            ])
            ->log('role_reinstated');

        // Notify security team
        // ... notification logic here ...

        // Return the new state
        return new Active($role);
    }
}
```

## Exercise 3: Creating a Permission History Feature

### Step 1: Create the PermissionHistory model and migration

First, create the migration:

```bash
php artisan make:migration create_permission_histories_table
```

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('permission_histories', function (Blueprint $table) {
            $table->id();
            $table->foreignId('permission_id')->constrained('permissions')->onDelete('cascade');
            $table->foreignId('user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('from_state');
            $table->string('to_state');
            $table->string('transition_type');
            $table->text('reason')->nullable();
            $table->text('notes')->nullable();
            $table->json('additional_data')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('permission_histories');
    }
};
```
