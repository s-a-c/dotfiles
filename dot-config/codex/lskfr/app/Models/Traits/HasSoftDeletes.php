<?php

namespace App\Models\Traits;

use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * Trait HasSoftDeletes
 *
 * This trait ensures that models have soft delete functionality.
 * It can be used in models that don't extend BaseModel but still need soft deletes.
 */
trait HasSoftDeletes
{
    use SoftDeletes;

    /**
     * Boot the trait.
     *
     * @return void
     */
    public static function bootHasSoftDeletes()
    {
        static::addGlobalScope('withTrashed', function ($query) {
            // This is a placeholder for any additional global scopes you might want to add
        });
    }

    /**
     * Get the name of the "deleted at" column.
     *
     * @return string
     */
    public function getDeletedAtColumn()
    {
        return defined('static::DELETED_AT') ? static::DELETED_AT : 'deleted_at';
    }

    /**
     * Get the fully qualified "deleted at" column.
     *
     * @return string
     */
    public function getQualifiedDeletedAtColumn()
    {
        return $this->qualifyColumn($this->getDeletedAtColumn());
    }
}
