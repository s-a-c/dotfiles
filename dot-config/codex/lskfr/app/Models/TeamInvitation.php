<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Str;
use Illuminate\Support\Carbon;
use App\Models\Team;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\HasFactory;

/**
 * Represents an invitation sent to a user to join a team.
 *
 * @extends Model<\App\Models\TeamInvitation>
 */
class TeamInvitation extends Model
{
    use HasFactory;
    /**
     * The attributes that are mass assignable.
     *
     * @var string[]
     */
    protected $fillable = [
        'team_id',
        'email',
        'token',
        'allow_subteams',
        'expires_at',
        'accepted_at',
        'invited_by',
    ];

    /**
     * The attributes that should be cast.
     *
     * @var array<string,string>
     */
    protected $casts = [
        'allow_subteams' => 'boolean',
        'expires_at'     => 'datetime',
        'accepted_at'    => 'datetime',
    ];

    /**
     * Get the team that the invitation belongs to.
     */
    public function team(): BelongsTo
    {
        return $this->belongsTo(Team::class);
    }

    /**
     * Get the user who sent the invitation.
     */
    public function inviter(): BelongsTo
    {
        return $this->belongsTo(User::class, 'invited_by');
    }

    /**
     * Generate a new invitation token.
     */
    public static function generateToken(): string
    {
        return Str::random(64);
    }

    /**
     * Determine if the invitation has expired.
     */
    public function hasExpired(): bool
    {
        return $this->expires_at instanceof Carbon && $this->expires_at->isPast();
    }

    /**
     * Accept the invitation by setting accepted_at.
     */
    public function accept(): void
    {
        $this->accepted_at = now();
        $this->save();
    }
}
