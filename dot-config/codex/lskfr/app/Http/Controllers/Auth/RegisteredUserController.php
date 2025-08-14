<?php

declare(strict_types=1);

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Auth\Events\Registered;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules;
use Inertia\Inertia;
use Inertia\Response;
use function event;
use function file_exists;
use function is_string;
use function json_decode;
use function storage_path;
use function to_route;

class RegisteredUserController extends Controller
{
    /**
     * Show the registration page.
     */
    public function create(): Response
    {
        return Inertia::render('auth/register');
    }

    /**
     * Handle an incoming registration request.
     *
     * @throws \Illuminate\Validation\ValidationException
     */
    public function store(Request $request): RedirectResponse
    {
        $request->validate([
            'given_name' => 'required|string|max:255',
            'family_name' => 'required|string|max:255',
            'email' => 'required|string|lowercase|email|max:255|unique:'.User::class,
            'password' => ['required', 'confirmed', Rules\Password::defaults()],
        ]);

        $user = User::create([
            'given_name' => $request->given_name,
            'family_name' => $request->family_name,
            'email' => $request->email,
            'password' => Hash::make($request->password),
        ]);

        // Handle avatar upload if provided
        if ($request->has('avatar_data')) {
            $avatarData = json_decode($request->avatar_data, true);

            if ($avatarData && isset($avatarData['type'])) {
                if ($avatarData['type'] === 'file' && isset($avatarData['file'])) {
                    // Handle file upload via Livewire's temporary upload
                    $file = $avatarData['file'];
                    if (is_string($file) && file_exists(storage_path('app/livewire-tmp/' . $file))) {
                        $user->addMedia(storage_path('app/livewire-tmp/' . $file))
                            ->toMediaCollection('avatar');
                    }
                } elseif ($avatarData['type'] === 'url' && isset($avatarData['url'])) {
                    // Handle URL-based avatar
                    $user->avatar = $avatarData['url'];
                    $user->save();
                }
            }
        }

        event(new Registered($user));

        Auth::login($user);

        return to_route('dashboard');
    }
}
