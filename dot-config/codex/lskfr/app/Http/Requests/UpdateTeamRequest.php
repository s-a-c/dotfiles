<?php

declare(strict_types=1);

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

/**
 * Validate input for updating a team.
 */
class UpdateTeamRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Get the validation rules.
     */
    public function rules(): array
    {
        $teamId = $this->route('team')->id ?? null;

        return [
            'name'          => ['sometimes', 'required', 'string', 'max:255'],
            'slug'          => [
                'sometimes', 'required', 'string', 'max:255',
                "unique:teams,slug,{$teamId}"
            ],
            'description'   => ['sometimes', 'nullable', 'string'],
            'is_active'     => ['sometimes', 'boolean'],
            'allow_subteams'=> ['sometimes', 'boolean'],
        ];
    }
}
