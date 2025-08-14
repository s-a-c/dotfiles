<?php
declare(strict_types=1);

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Notification;
use Illuminate\Support\Facades\Mail;
use App\Models\Team;
use App\Models\TeamInvitation;
use App\Notifications\TeamInvitationNotification;
use Illuminate\Support\Carbon;

/**
 * Controller for sending and accepting team invitations.
 */
class TeamInvitationController
{
    /**
     * Send a new invitation to join a team.
     *
     * @param Request $request
     * @param Team    $team
     * @return \Illuminate\Http\RedirectResponse
     */
    public function send(Request $request, Team $team)
    {
        $data = $request->validate([
            'email' => 'required|email',
            'allow_subteams' => 'sometimes|boolean',
            'expires_at' => 'sometimes|date|after:now',
        ]);

        // Create invitation
        $invitation = new TeamInvitation();
        $invitation->team_id = $team->id;
        $invitation->email = $data['email'];
        $invitation->token = TeamInvitation::generateToken();
        $invitation->allow_subteams = $data['allow_subteams'] ?? $team->allow_subteams;
        $invitation->expires_at = $data['expires_at'] ?? Carbon::now()->addWeek();
        $invitation->invited_by = $request->user()->id;
        $invitation->save();

        // Queue the invitation email via Mailable
        Mail::to($invitation->email)
            ->queue(new \App\Mail\TeamInvitationMail($invitation));

        // Send notification (queued by ShouldQueue) via Notification system
        Notification::route('mail', $invitation->email)
            ->notify(new TeamInvitationNotification($invitation));

        return redirect()->back()
            ->with('status', 'Invitation sent to ' . $invitation->email);
    }

    /**
     * Accept an invitation and add the authenticated user to the team.
     *
     * @param Request $request
     * @param string  $token
     * @return \Illuminate\Http\RedirectResponse
     */
    public function accept(Request $request, string $token)
    {
        $invitation = TeamInvitation::where('token', $token)->firstOrFail();

        // Expiration check
        if ($invitation->hasExpired()) {
            return redirect()->route('home')
                ->with('error', 'This invitation has expired.');
        }

        // Ensure user is logged in
        if (! $request->user()) {
            return redirect()->route('login');
        }

        // Ensure the correct user
        if ($request->user()->email !== $invitation->email) {
            return redirect()->route('home')
                ->with('error', 'You are not the invited user.');
        }

        // Add to team
        $team = $invitation->team;
        $team->addMember($request->user());

        // Mark invitation accepted
        $invitation->accepted_at = Carbon::now();
        $invitation->save();

        return redirect()->route('home')
            ->with('status', 'You have joined the team ' . $team->name . '.');
    }
}