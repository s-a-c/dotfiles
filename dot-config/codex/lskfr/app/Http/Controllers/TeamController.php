<?php
declare(strict_types=1);

namespace App\Http\Controllers;

use App\Http\Requests\StoreTeamRequest;
use App\Http\Requests\UpdateTeamRequest;
use App\Models\Team;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Inertia\Response;

/**
 * Controller handling CRUD for teams.
 */
class TeamController extends Controller
{
    public function __construct()
    {
        $this->authorizeResource(Team::class, 'team');
    }

    /**
     * Display a listing of the user's teams.
     */
    public function index(Request $request): Response
    {
        $teams = Team::whereRelation('members', 'user_id', $request->user()->id)
            ->get();

        return Inertia::render('Teams/Index', compact('teams'));
    }

    /**
     * Show the form for creating a new team.
     */
    public function create(): Response
    {
        return Inertia::render('Teams/Create');
    }

    /**
     * Store a newly created team.
     */
    public function store(StoreTeamRequest $request): RedirectResponse
    {
        $data = $request->validated();
        $data['owner_id'] = $request->user()->id;

        if (! empty($data['parent_id'])) {
            $parent = Team::findOrFail((int) $data['parent_id']);
            $team = $parent->createSubteam($data);
        } else {
            $team = Team::create($data);
        }

        return redirect()->route('teams.index')
            ->with('status', "Team '{$team->name}' created.");
    }

    /**
     * Display the specified team.
     */
    public function show(Team $team): Response
    {
        return Inertia::render('Teams/Show', [
            'team' => $team->load('members'),
        ]);
    }

    /**
     * Show the form for editing the team.
     */
    public function edit(Team $team): Response
    {
        return Inertia::render('Teams/Edit', compact('team'));
    }

    /**
     * Update the specified team.
     */
    public function update(UpdateTeamRequest $request, Team $team): RedirectResponse
    {
        $team->update($request->validated());

        return redirect()->route('teams.show', $team)
            ->with('status', 'Team updated.');
    }

    /**
     * Remove the specified team.
     */
    public function destroy(Team $team): RedirectResponse
    {
        $team->delete();

        return redirect()->route('teams.index')
            ->with('status', 'Team deleted.');
    }
<<<<<<< HEAD
}
=======
}
>>>>>>> origin/develop
