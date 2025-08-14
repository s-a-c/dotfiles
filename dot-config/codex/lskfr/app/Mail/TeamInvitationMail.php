<?php

declare(strict_types=1);

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;
use Illuminate\Contracts\Queue\ShouldQueue;
use App\Models\TeamInvitation;

/**
 * Mailable for sending team invitations.
 */
class TeamInvitationMail extends Mailable implements ShouldQueue
{
    use Queueable, SerializesModels;

    /**
     * The queue on which this mail will be sent.
     *
     * @var string
     */
    public string $queue = 'mailables';

    /**
     * The team invitation instance.
     *
     * @var TeamInvitation
     */
    public TeamInvitation $invitation;

    /**
     * URL for accepting the invitation.
     *
     * @var string
     */
    public string $acceptUrl;

    /**
     * Create a new message instance.
     */
    public function __construct(TeamInvitation $invitation)
    {
        $this->invitation = $invitation;
        $this->acceptUrl = url('/invitations/'.$invitation->token.'/accept');
    }

    /**
     * Build the message.
     */
    public function build(): self
    {
        return $this
            ->subject('Invitation to join team ' . $this->invitation->team->name)
            ->markdown('emails.team.invitation', [
                'invitation' => $this->invitation,
                'acceptUrl' => $this->acceptUrl,
            ]);
    }
}
