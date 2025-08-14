<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use App\Models\Traits\HasBaseModelFeatures;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Pivot model for team-user relationships.
 *
 * @extends Model<\App\Models\TeamUser>
 */
class TeamUser extends Model
{
    use HasBaseModelFeatures;
    /**
     * The table associated with the model.
     *
     * @var string
     */
    protected $table = 'team_users';

    /**
     * The attributes that are mass assignable.
     *
     * @var string[]
     */
    protected $fillable = [
        'team_id',
        'user_id',
        'role',
    ];

    /**
     * Get the team associated with this pivot.
     */
    public function team(): BelongsTo
    {
        return $this->belongsTo(Team::class);
    }

    /**
     * Get the user associated with this pivot.
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
