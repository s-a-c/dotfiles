<?php

namespace App\Providers;

use App\Http\Livewire\UploadAvatar;
use Illuminate\Support\ServiceProvider;
use Livewire\Livewire;

class LivewireServiceProvider extends ServiceProvider
{
    /**
     * Register services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap services.
     */
    public function boot(): void
    {
        Livewire::component('upload-avatar', UploadAvatar::class);
    }
}
