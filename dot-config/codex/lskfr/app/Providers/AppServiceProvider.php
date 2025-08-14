<?php

declare(strict_types=1);

namespace App\Providers;

use App\Models\User;
use Carbon\CarbonImmutable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Date;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\URL;
use Illuminate\Support\Facades\Vite;
use Illuminate\Support\Number;
use Illuminate\Support\ServiceProvider;
use Laravel\Passport\Passport;
use function app;
use function in_array;

class AppServiceProvider extends ServiceProvider
{
    public function boot(): void
    {
        /*Gate::before(function (User $user, string $ability) {
            return $user->id === 1;
        });*/

        Number::useLocale('en_GB');
        URL::defaults(['domain' => '']);
        if (! $this->app->isLocal()) {
            URL::forceScheme('https');
        }
        Model::unguard();

        /**
         * Force correct Typesense API key very early
         */
        // config(['scout.typesense.client-settings.api_key' => 'LARAVEL_HERD']);

        $this->configureCarbon();
        $this->configureCommands();
        $this->configureDatabase();
        $this->configureModels();
        $this->configureUrl();
        $this->configureVite();

        Passport::hashClientSecrets();

        /**
         * Register the Pulse gate.
         *
         * This gate determines who can access Pulse in non-local environments.
         */
        Gate::define('viewPulse', function (User $user) {
            return match(true) {
                app()->environment('local') => true,
                $user->is_admin => true,
                in_array($user->email, [
                    'embrace.s0ul+s-a-c@gmail.com',
                    'taylor@laravel.com',
                ]), => true,
                default => false,
            };
        });
    }

    /**
     * Configure the application's carbon.
     */
    private function configureCarbon(): void
    {

        Date::use(CarbonImmutable::class);
    }

    /**
     * Configure the application's commands.
     */
    private function configureCommands(): void
    {
        Artisan::command('inspire', function () {
            $this->comment(Inspiring::quote());
        })->purpose('Display an inspiring quote');
    }

    /**
     * Configure the application's database.
     */
    private function configureDatabase(): void
    {
        DB::prohibitDestructiveCommands(
            $this->app->isProduction()
            && !$this->app->runningInConsole()
            && !$this->app->runningUnitTests()
            && !$this->app->isDownForMaintenance(),
        );
    }

    /**
     * Configure the application's models.
     */
    private function configureModels(): void
    {

        Model::automaticallyEagerLoadRelationships();
        Model::preventAccessingMissingAttributes(!$this->app->isProduction());
        Model::preventLazyLoading(!$this->app->isProduction());
        Model::preventSilentlyDiscardingAttributes(!$this->app->isProduction());
        Model::shouldBeStrict(!$this->app->isProduction());
        Model::unguard(!$this->app->isProduction());
    }

    /**
     * Configure the application's url.
     */
    private function configureUrl(): void
    {

        URL::forceScheme('https');
    }

    /**
     * Configure the application's vite.
     */
    private function configureVite(): void
    {

        Vite::useBuildDirectory('build')
            ->withEntryPoints([
                'resources/js/app.js',
            ]);
    }
}
