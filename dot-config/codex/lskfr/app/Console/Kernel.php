<?php

namespace App\Console;

use Illuminate\Console\Scheduling\Schedule;
use Illuminate\Foundation\Console\Kernel as ConsoleKernel;
use Laravel\Passport\Console\PurgeCommand as PassportPurgeCommand;
use Laravel\Telescope\Console\PruneCommand as TelescopePruneCommand;
use Spatie\Health\Commands\RunHealthChecksCommand;

class Kernel extends ConsoleKernel
{
    /**
     * Define the application's command schedule.
     */
    protected function schedule(Schedule $schedule): void
    {
        // Purge expired Passport tokens hourly
        $schedule->command('passport:purge')
            ->hourly()
            ->description('Purge expired OAuth tokens')
            ->appendOutputTo(storage_path('logs/passport-purge.log'));
        
        // Prune old Telescope entries daily
        $schedule->command('telescope:prune --hours=48')
            ->daily()
            ->description('Prune old Telescope entries')
            ->appendOutputTo(storage_path('logs/telescope-prune.log'));
        
        /**
         * Run application health checks every minute.
         *
         * This uses Spatie's Health package to monitor various aspects of the application.
         * Results are stored and can be viewed through the health dashboard.
         *
         * @see \Spatie\Health\Commands\RunHealthChecksCommand
         * @see https://spatie.be/docs/laravel-health
         */
        $schedule->command(RunHealthChecksCommand::class)
            ->everyMinute()
            ->withoutOverlapping()
            ->runInBackground()
            ->description('Run application health checks')
            ->appendOutputTo(storage_path('logs/health-checks.log'))
            ->onFailure(function () {
                \Illuminate\Support\Facades\Log::error('Health checks failed to run');
            });

        // Process mailables queue every 5 minutes
        $schedule->command('queue:work --queue=mailables --once --tries=3')
            ->everyFiveMinutes()
            ->withoutOverlapping()
            ->runInBackground()
            ->description('Process mailables queue')
            ->appendOutputTo(storage_path('logs/mailables-queue.log'));

        // Process notifications queue every 5 minutes
        $schedule->command('queue:work --queue=notifications --once --tries=3')
            ->everyFiveMinutes()
            ->withoutOverlapping()
            ->runInBackground()
            ->description('Process notifications queue')
            ->appendOutputTo(storage_path('logs/notifications-queue.log'));
    }

    /**
     * Register the commands for the application.
     */
    protected function commands(): void
    {
        $this->load(__DIR__.'/Commands');

        require base_path('routes/console.php');
    }
}
