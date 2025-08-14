<?php

declare(strict_types=1);

namespace App\Models;

use App\Traits\HasBaseModelFeatures;
use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use Spatie\MediaLibrary\HasMedia;
use Spatie\MediaLibrary\InteractsWithMedia;

class User extends Authenticatable implements MustVerifyEmail, HasMedia
{
    use HasApiTokens,
        HasFactory,
        Notifiable,
        InteractsWithMedia,
        HasBaseModelFeatures;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'name',
        'email',
        'password',
        'is_active',
        'is_admin',
        'ulid',
        'current_team_id', // Added current_team_id to fillable
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var array<int, string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * The attributes that should be cast.
     *
     * @var array<string, string>
     */
    protected $casts = [
        'email_verified_at' => 'datetime',
        'password' => 'hashed',
        'is_active' => 'boolean',
        'is_admin' => 'boolean',
    ];

    /**
     * Get the user's teams.
     */
    public function teams()
    {
        return $this->belongsToMany(Team::class, 'team_users')
                    ->withPivot('role')
                    ->withTimestamps();
    }

    /**
     * Get the user's owned teams.
     */
    public function ownedTeams()
    {
        return $this->hasMany(Team::class, 'owner_id');
    }

    /**
     * Get the user's current team.
     */
    public function currentTeam()
    {
        return $this->belongsTo(Team::class, 'current_team_id');
    }

    /**
     * Switch the user's current team.
     *
     * @param  Team|int  $team
     * @return void
     */
    public function switchTeam($team)
    {
        if (is_numeric($team)) {
            $team = Team::find($team);
        }

        $this->update(['current_team_id' => $team->id]);
    }
}
