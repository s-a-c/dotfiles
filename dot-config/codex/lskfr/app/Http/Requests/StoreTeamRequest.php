<?php

declare(strict_types=1);

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

/**
 * Validate input for creating a new team.
 */
class StoreTeamRequest extends FormRequest
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
        return [
            'name'          => ['required', 'string', 'max:255'],
            'slug'          => ['required', 'string', 'max:255', 'unique:teams,slug'],
            'description'   => ['sometimes', 'nullable', 'string'],
            'parent_id'     => ['sometimes', 'nullable', 'exists:teams,id'],
            'is_active'     => ['sometimes', 'boolean'],
            'allow_subteams'=> ['sometimes', 'boolean'],
        ];
    }

    /**
     * Custom error messages.
     */
    public function messages(): array
    {
        return [
            'name.required'      => 'A team name is required.',
            'slug.required'      => 'A team slug is required.',
            'slug.unique'        => 'This slug is already in use.',
            'parent_id.exists'   => 'The selected parent team is invalid.',
        ];
    }
}
