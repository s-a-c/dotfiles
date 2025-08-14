<?php

declare(strict_types=1);

namespace App\Policies;

use App\Models\Team;
use App\Models\User;
use Illuminate\Auth\Access\HandlesAuthorization;

/**
 * Authorization policy for Team model.
 */
class TeamPolicy
{
    use HandlesAuthorization;

    /**
     * Determine whether the user can view any teams.
     */
    public function viewAny(User $user): bool
    {
        return true;
    }

    /**
     * Determine whether the user can view a specific team.
     */
    public function view(User $user, Team $team): bool
    {
        return $team->hasMemberInHierarchy($user);
    }

    /**
     * Determine whether the user can create a team (or subteam).
     *
     * @param  User       $user
     * @param  Team|null  $parent
     */
    public function create(User $user, ?Team $parent = null): bool
    {
        if ($user->is_admin) {
            return true;
        }

        if ($parent) {
            return $parent->hasMemberInHierarchy($user)
                && $parent->allowsSubteams();
        }

        return false;
    }

    /**
     * Determine whether the user can update the team.
     */
    public function update(User $user, Team $team): bool
    {
        return $team->owner_id === $user->id
            || $user->is_admin;
    }

    /**
     * Determine whether the user can delete the team.
     */
    public function delete(User $user, Team $team): bool
    {
        return $team->owner_id === $user->id
            || $user->is_admin;
    }

    /**
     * Determine whether the user can manage team members.
     */
    public function manageMembers(User $user, Team $team): bool
    {
        return $team->owner_id === $user->id
            || $user->is_admin;
    }

    /**
     * Determine whether the user can create a subteam under this team.
     */
    public function createSubteam(User $user, Team $team): bool
    {
        return $this->create($user, $team);
    }
}
