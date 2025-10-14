·z<?php

declare(strict_types=1);

namespace App\Models\Traits;

use App\Models\User;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\Pivot;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\Log;

/**
 * Trait HasUserTracking
 *
 * Automatically tracks and maintains created_by, updated_by, and deleted_by attributes
 * for Eloquent models.
 *
 * Requirements:
 * - The model must have created_by_id, updated_by_id, and deleted_by_id columns in the database
 * - The model should use SoftDeletes trait if deleted_by tracking is needed
 *
 * @property int|null $created_by_id ID of the user who created this record
 * @property int|null $updated_by_id ID of the user who last updated this record
 * @property int|null $deleted_by_id ID of the user who deleted this record (for soft deletes)
 * @property-read \App\Models\User|null $createdBy User who created this record
 * @property-read \App\Models\User|null $updatedBy User who last updated this record
 * @property-read \App\Models\User|null $deletedBy User who deleted this record
 */
trait HasUserTracking
{
    /**
     * Flag to enable/disable user tracking.
     */
    private static bool $userTrackingEnabled = true;

    /**
     * Boot the HasUserTracking trait.
     */
    protected static function bootHasUserTracking(): void
    {
        // Set created_by and updated_by on creation
        static::creating(function (Model $model): void {
            if (! static::$userTrackingEnabled || ! static::isUserTrackingEnabled()) {
                return;
            }

            $userId = self::getCurrentUserId();

            if ($userId) {
                $createdByColumn = $model->getUserTrackingColumnName('created');
                $updatedByColumn = $model->getUserTrackingColumnName('updated');

                if (! $model->{$createdByColumn}) {
                    $model->{$createdByColumn} = $userId;
                }

                if (! $model->{$updatedByColumn}) {
                    $model->{$updatedByColumn} = $userId;
                }
            }
        });

        // Set updated_by on update
        static::updating(function (Model $model): void {
            if (! static::$userTrackingEnabled || ! static::isUserTrackingEnabled()) {
                return;
            }

            $userId = self::getCurrentUserId();

            if ($userId) {
                $updatedByColumn = $model->getUserTrackingColumnName('updated');
                $model->{$updatedByColumn} = $userId;

                // Log detailed update activity if the activity log package is available
                if (class_exists(\Spatie\Activitylog\ActivityLogger::class)) {
                    self::logModelActivity($model, $userId, 'updated');
                }
            }
        });

        // Set deleted_by on deletion
        static::deleting(function (Model $model): void {
            if (! static::$userTrackingEnabled || ! static::isUserTrackingEnabled()) {
                return;
            }

            $userId = self::getCurrentUserId();

            if ($userId) {
                $deletedByColumn = $model->getUserTrackingColumnName('deleted');

                // Handle different deletion scenarios
                if (method_exists($model, 'isForceDeleting') && ! $model->isForceDeleting()) {
                    // For soft deletes
                    $model->{$deletedByColumn} = $userId;
                    $model->save();
                } elseif (! method_exists($model, 'isForceDeleting')) {
                    // For hard deletes, we can't save to the model after deletion
                    // Log to a separate table or log file
                    self::logHardDelete($model, $userId);
                }

                // Default case (force deleting) - handled by forceDeleting event
            }
        });

        // Track force deletes
        static::forceDeleting(function (Model $model): void {
            if (! static::$userTrackingEnabled || ! static::isUserTrackingEnabled()) {
                return;
            }

            $userId = self::getCurrentUserId();

            if ($userId) {
                // Log the force delete since we can't save to the model
                self::logForceDelete($model, $userId);
            }
        });

        // Track restores of soft deleted models
        static::restoring(function (Model $model): void {
            if (! static::$userTrackingEnabled || ! static::isUserTrackingEnabled()) {
                return;
            }

            $userId = self::getCurrentUserId();

            if ($userId) {
                $updatedByColumn = $model->getUserTrackingColumnName('updated');
                $model->{$updatedByColumn} = $userId;

                // Clear the deleted_by field
                $deletedByColumn = $model->getUserTrackingColumnName('deleted');
                $model->{$deletedByColumn} = null;

                // Log the restore activity
                if (class_exists(\Spatie\Activitylog\ActivityLogger::class)) {
                    self::logModelActivity($model, $userId, 'restored');
                }
            }
        });
    }

    /**
     * Get the user who created this record.
     */
    public function createdBy(): BelongsTo
    {
        return $this->belongsTo($this->getUserClass(), $this->getUserTrackingColumnName('created'));
    }

    /**
     * Get the user who last updated this record.
     */
    public function updatedBy(): BelongsTo
    {
        return $this->belongsTo($this->getUserClass(), $this->getUserTrackingColumnName('updated'));
    }

    /**
     * Get the user who deleted this record (for soft deletes).
     */
    public function deletedBy(): BelongsTo
    {
        return $this->belongsTo($this->getUserClass(), $this->getUserTrackingColumnName('deleted'));
    }

    /**
     * Get the column name used for tracking the specified user action type.
     *
     * @param  string  $type  The type of action (created, updated, deleted)
     *
     * @return string The column name
     */
    protected function getUserTrackingColumnName(string $type): string
    {
        $defaultColumns = config('user-tracking.default_columns', [
            'created' => 'created_by_id',
            'updated' => 'updated_by_id',
            'deleted' => 'deleted_by_id',
        ]);

        return $defaultColumns[$type] ?? $type.'_by_id';
    }

    /**
     * Get the user model class name.
     *
     * @return string The fully qualified class name of the user model
     */
    protected function getUserClass(): string
    {
        return config('user-tracking.user_model', Config::get('auth.providers.users.model', User::class));
    }

    /**
     * Get the current user ID from various authentication contexts.
     *
     * @return int|null The current user ID or null if no user is authenticated
     */
    protected static function getCurrentUserId(): ?int
    {
        // Handle different authentication contexts
        if (Auth::check()) {
            return Auth::id();
        }

        if (class_exists(\Laravel\Sanctum\Sanctum::class) && Auth::guard('sanctum')->check()) {
            return Auth::guard('sanctum')->id();
        }

        return null;

    }

    /**
     * Scope a query to only include records created by a specific user.
     */
    public function scopeCreatedBy(Builder $builder, int $userId): Builder
    {
        return $builder->where($this->getUserTrackingColumnName('created'), $userId);
    }

    /**
     * Scope a query to only include records updated by a specific user.
     */
    public function scopeUpdatedBy(Builder $builder, int $userId): Builder
    {
        return $builder->where($this->getUserTrackingColumnName('updated'), $userId);
    }

    /**
     * Scope a query to only include records deleted by a specific user.
     */
    public function scopeDeletedBy(Builder $builder, int $userId): Builder
    {
        return $builder->where($this->getUserTrackingColumnName('deleted'), $userId);
    }

    /**
     * Check if the record was created by a specific user.
     */
    public function wasCreatedBy(int $userId): bool
    {
        return $this->{$this->getUserTrackingColumnName('created')} == $userId;
    }

    /**
     * Check if the record was updated by a specific user.
     */
    public function wasUpdatedBy(int $userId): bool
    {
        return $this->{$this->getUserTrackingColumnName('updated')} == $userId;
    }

    /**
     * Check if the record was deleted by a specific user.
     */
    public function wasDeletedBy(int $userId): bool
    {
        return $this->{$this->getUserTrackingColumnName('deleted')} == $userId;
    }

    /**
     * Temporarily disable user tracking for a callback.
     */
    public static function withoutUserTracking(callable $callback): mixed
    {
        $originalValue = static::$userTrackingEnabled;
        static::$userTrackingEnabled = false;

        try {
            return $callback();
        } finally {
            static::$userTrackingEnabled = $originalValue;
        }
    }

    /**
     * Check if user tracking is enabled globally via config.
     */
    protected static function isUserTrackingEnabled(): bool
    {
        return config('user-tracking.enabled', true);
    }

    /**
     * Log a force delete operation.
     */
    protected static function logForceDelete(Model $model, int $userId): void
    {
        // Determine logging method based on available packages
        if (class_exists(\Spatie\Activitylog\ActivityLogger::class)) {
            // If the activity log package is available, use it
            self::logModelActivity($model, $userId, 'force_deleted');
        } else {
            // Otherwise, log to the application log
            Log::info('Model force deleted', [
                'model_id' => $model->getKey(),
                'model_type' => $model::class,
                'user_id' => $userId,
                'timestamp' => now(),
            ]);
        }
    }

    /**
     * Log a hard delete operation.
     */
    protected static function logHardDelete(Model $model, int $userId): void
    {
        // Determine logging method based on available packages
        if (class_exists(\Spatie\Activitylog\ActivityLogger::class)) {
            // If the activity log package is available, use it
            self::logModelActivity($model, $userId, 'deleted');
        } else {
            // Otherwise, log to the application log
            Log::info('Model deleted', [
                'model_id' => $model->getKey(),
                'model_type' => $model::class,
                'user_id' => $userId,
                'timestamp' => now(),
            ]);
        }
    }

    /**
     * Log model activity using the activity log package.
     */
    protected static function logModelActivity(Model $model, int $userId, string $action): void
    {
        // Determine if activity logging is available
        if (function_exists('activity')) {
            activity()
                ->causedBy($userId)
                ->performedOn($model)
                ->withProperties([
                    'action' => $action,
                    'model_id' => $model->getKey(),
                    'model_type' => $model::class,
                ])
                ->log($action);
        }

        // Do nothing if activity function doesn't exist
    }

    /**
     * Get a new pivot model instance with user tracking.
     *
     * @param  Model  $model  The parent model
     * @param  array  $attributes  The pivot attributes
     * @param  string  $table  The pivot table
     * @param  bool  $exists  Whether the pivot exists
     * @param  string|null  $using  The custom pivot class
     *
     * @return Pivot
     */
    public function newPivot(Model $model, array $attributes, $table, $exists, $using = null)
    {
        $pivot = parent::newPivot($model, $attributes, $table, $exists, $using);

        if (! static::$userTrackingEnabled || ! static::isUserTrackingEnabled()) {
            return $pivot;
        }

        $userId = self::getCurrentUserId();

        // Using match to handle different pivot record scenarios
        if ($userId) {
            if (! $exists) {
                // New pivot record
                $createdByColumn = $this->getUserTrackingColumnName('created');
                $updatedByColumn = $this->getUserTrackingColumnName('updated');

                if (isset($pivot->{$createdByColumn})) {
                    $pivot->{$createdByColumn} = $userId;
                }

                if (isset($pivot->{$updatedByColumn})) {
                    $pivot->{$updatedByColumn} = $userId;
                }
            } else {
                // Existing pivot record being updated
                $updatedByColumn = $this->getUserTrackingColumnName('updated');

                if (isset($pivot->{$updatedByColumn})) {
                    $pivot->{$updatedByColumn} = $userId;
                }
            }
        }

        return $pivot;
    }

    /**
     * Get the history of user actions on this model.
     *
     * @return array<string, mixed>
     */
    public function getUserActionHistory(): array
    {
        $createdByColumn = $this->getUserTrackingColumnName('created');
        $updatedByColumn = $this->getUserTrackingColumnName('updated');
        $deletedByColumn = $this->getUserTrackingColumnName('deleted');

        $history = [
            'created' => [
                'user_id' => $this->{$createdByColumn},
                'user' => $this->createdBy,
                'timestamp' => $this->created_at,
            ],
            'updated' => [
                'user_id' => $this->{$updatedByColumn},
                'user' => $this->updatedBy,
                'timestamp' => $this->updated_at,
            ],
        ];

        // Add deleted info if the model uses soft deletes
        // Handle soft delete information
        if (method_exists($this, 'isForceDeleting') && $this->deleted_at !== null) {
            $history['deleted'] = [
                'user_id' => $this->{$deletedByColumn},
                'user' => $this->deletedBy,
                'timestamp' => $this->deleted_at,
            ];
        }

        // Add detailed history if activity log is available
        // Handle activity log availability
        if (class_exists(\Spatie\Activitylog\Models\Activity::class)) {
            $history['activity_log'] = $this->getDetailedActivityHistory();
        }

        return $history;
    }

    /**
     * Get detailed activity history from the activity log.
     *
     * @return array<int, array<string, mixed>>
     */
    protected function getDetailedActivityHistory(): array
    {
        // Handle activity log availability
        if (! class_exists(\Spatie\Activitylog\Models\Activity::class)) {
            return [];
        }

        $activityClass = \Spatie\Activitylog\Models\Activity::class;

        $activities = $activityClass::where([
            'subject_type' => $this::class,
            'subject_id' => $this->getKey(),
        ])->orderBy('created_at', 'desc')->get();

        return $activities->map(fn ($activity): array => [
            'action' => $activity->description,
            'user_id' => $activity->causer_id,
            'user' => $activity->causer,
            'timestamp' => $activity->created_at,
            'properties' => $activity->properties,
        ])->toArray();
    }
}
¢[ ¢[£[
£[©[ ©[ª[
ª[«[ «[®[
®[¯[ ¯[±[
±[Ð[ Ð[Ñ[
Ñ[Ø[ Ø[Ù[
Ù[ä[ ä[å[
å[ˆ\ ˆ\‰\
‰\‘\ ‘\’\
’\˜\ ˜\™\
™\·\ ·\¸\
¸\¾\ ¾\¿\
¿\Æ\ Æ\Ç\
Ç\î\ î\ï\
ï\ü\ ü\ý\
ý\ƒ] ƒ]„]
„]¢] ¢]©]
©]ä] ä]ç]
ç]è] è]é]
é]Ç^ Ç^Ê^
Ê^Ë^ Ë^Ì^
Ì^‘u ‘u’u
<<<<<<< HEAD
’u·z "(3ae679aae66fa0c02e851818130d386ac099924e2Kfile:///Users/s-a-c/Herd/lsk-livewire/app/Models/Traits/HasUserTracking.php:%file:///Users/s-a-c/Herd/lsk-livewire
=======
’u·z "(3ae679aae66fa0c02e851818130d386ac099924e2Kfile:///Users/s-a-c/Herd/lsk-livewire/app/Models/Traits/HasUserTracking.php:%file:///Users/s-a-c/Herd/lsk-livewire
>>>>>>> origin/develop
