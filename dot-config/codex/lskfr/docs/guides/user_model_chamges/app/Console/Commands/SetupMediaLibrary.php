<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\Artisan;

class SetupMediaLibrary extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'media:setup';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Setup the media library with proper configuration and symbolic links';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $this->info('Setting up Media Library...');

        // Publish the media library migrations
        $this->info('Publishing Media Library migrations...');
        Artisan::call('vendor:publish', [
            '--provider' => 'Spatie\MediaLibrary\MediaLibraryServiceProvider',
            '--tag' => 'migrations',
        ]);
        $this->info('Media Library migrations published successfully.');

        // Publish the media library config
        $this->info('Publishing Media Library config...');
        Artisan::call('vendor:publish', [
            '--provider' => 'Spatie\MediaLibrary\MediaLibraryServiceProvider',
            '--tag' => 'config',
        ]);
        $this->info('Media Library config published successfully.');

        // Run the migrations
        $this->info('Running migrations...');
        Artisan::call('migrate');
        $this->info('Migrations completed successfully.');

        // Create the symbolic link for media storage
        $this->info('Creating symbolic link for media storage...');
        Artisan::call('storage:link', [
            '--disk' => 'media',
        ]);
        $this->info('Symbolic link created successfully.');

        $this->info('Media Library setup completed successfully!');
        $this->info('You can now use the Media Library for avatar uploads.');

        return Command::SUCCESS;
    }
}
