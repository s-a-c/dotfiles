<?php

declare(strict_types=1);

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use App\Models\Team;

/**
 * Validate input for sending a team invitation.
 */
class StoreInvitationRequest extends FormRequest
{
    /**
     * Determine if the user can make this request.
     */
    public function authorize(): bool
    {
        $team = $this->route('team');

        return $team
            && $this->user()
            && $this->user()->can('manageMembers', $team);
    }

    /**
     * Get the validation rules.
     */
    public function rules(): array
    {
        return [
            'email'         => ['required', 'email'],
            'allow_subteams'=> ['sometimes', 'boolean'],
            'expires_at'    => ['sometimes', 'date', 'after:now'],
        ];
    }

    /**
     * Custom error messages.
     */
    public function messages(): array
    {
        return [
            'email.required' => 'An email address is required.',
            'email.email'    => 'Please provide a valid email address.',
            'expires_at.after'=> 'Expiration date must be in the future.',
        ];
    }
}
