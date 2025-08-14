<?php

declare(strict_types=1);

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Notification;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use App\Models\TeamInvitation;

/**
 * Notification for team invitations.
 */
class TeamInvitationNotification extends Notification implements ShouldQueue
{
    use Queueable;

    /**
     * The queue on which this notification will be sent.
     *
     * @var string
     */
    public string $queue = 'notifications';

    /**
     * The team invitation instance.
     *
     * @var TeamInvitation
     */
    protected TeamInvitation $invitation;

    /**
     * Create a new notification instance.
     */
    public function __construct(TeamInvitation $invitation)
    {
        $this->invitation = $invitation;
    }

    /**
     * Get the notification's delivery channels.
     */
    public function via($notifiable): array
    {
        return ['mail'];
    }

    /**
     * Get the mail representation of the notification.
     */
    public function toMail($notifiable): MailMessage
    {
        $acceptUrl = url('/invitations/'.$this->invitation->token.'/accept');

        return (new MailMessage)
            ->subject('Invitation to join team ' . $this->invitation->team->name)
            ->greeting('Hello!')
            ->line('You have been invited by ' . $this->invitation->inviter->name .
                ' to join the team "' . $this->invitation->team->name . '".')
            ->line($this->invitation->allow_subteams
                ? 'You will have permission to create subteams.'
                : 'You will not have permission to create subteams.')
            ->action('Accept Invitation', $acceptUrl)
            ->line('This invitation expires on ' . $this->invitation->expires_at->toDayDateTimeString() . '.')
            ->line('If you did not expect this invitation, you can ignore this email.');
    }
}
