<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use Livewire\Volt\Volt;
use function config;
use function resource_path;

class VoltServiceProvider extends ServiceProvider
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
        Volt::mount([
            resource_path('views/pages'),
            config('livewire.view_path', resource_path('views/livewire')),
        ]);
    }
}
