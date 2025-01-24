Vim�UnDo�  M:��V.���#�^��&PCP̑�8�{���   '           for   !                          g��I    _�                             ����                                                                                                                                                                                                                                                                                                                                                             g��'     �                 4import defaultTheme from 'tailwindcss/defaultTheme';   'import forms from '@tailwindcss/forms';   1import typography from '@tailwindcss/typography';       +/** @type {import('tailwindcss').Config} */   export default {       content: [   [        './vendor/laravel/framework/src/Illuminate/Pagination/resources/views/*.blade.php',   4        './vendor/laravel/jetstream/**/*.blade.php',   *        './storage/framework/views/*.php',   +        './resources/views/**/*.blade.php',       ],           theme: {           extend: {               fontFamily: {   C                sans: ['Figtree', ...defaultTheme.fontFamily.sans],               },   
        },       },       !    plugins: [forms, typography],   };5��                                  �             5�_�                            ����                                                                                                                                                                                                                                                                                                                                                             g��H    �                          for�   !            �                   �               5��                                           �      �                          �              �       5�_�                            ����                                                                                                                                                                                                                                                                                                                                                             g��1     �              �              $   {   5    "$schema": "https://getcomposer.org/schema.json",       "name": "laravel/laravel",       "type": "project",   I    "description": "The skeleton application for the Laravel framework.",       "keywords": [           "laravel",           "framework"       ],       "license": "MIT",       "require": {           "php": "^8.2",   &        "laravel/framework": "^11.31",   $        "laravel/jetstream": "^5.3",   "        "laravel/sanctum": "^4.0",   !        "laravel/tinker": "^2.9",   #        "livewire/livewire": "^3.0"       },       "require-dev": {   "        "fakerphp/faker": "^1.23",           "laravel/pail": "^1.1",            "laravel/pint": "^1.13",            "laravel/sail": "^1.26",   "        "mockery/mockery": "^1.6",   '        "nunomaduro/collision": "^8.1",           "pestphp/pest": "^3.7",   -        "pestphp/pest-plugin-laravel": "^3.0"       },       "autoload": {           "psr-4": {               "App\\": "app/",   ;            "Database\\Factories\\": "database/factories/",   6            "Database\\Seeders\\": "database/seeders/"   	        }       },       "a�   $   %        �   #   %              "autoload-dev": {           "psr-4": {               "Tests\\": "tests/"   	        }       },       "scripts": {           "post-autoload-dump": [   H            "Illuminate\\Foundation\\ComposerScripts::postAutoloadDump",   2            "@php artisan package:discover --ansi"   
        ],           "post-update-cmd": [   M            "@php artisan vendor:publish --tag=laravel-assets --ansi --force"   
        ],   &        "post-root-package-install": [   N            "@php -r \"file_exists('.env') || copy('.env.example', '.env');\""   
        ],   $        "post-create-project-cmd": [   /            "@php artisan key:generate --ansi",   h            "@php -r \"file_exists('database/database.sqlite') || touch('database/database.sqlite');\"",   4            "@php artisan migrate --graceful --ansi"   
        ],           "dev": [   6            "Composer\\Config::disableProcessTimeout",   �            "pnpm exec concurrently -c \"#93c5fd,#c4b5fd,#fb7185,#fdba74\" \"php artisan serve\" \"php artisan queue:listen --tries=1\" \"php artisan pail --timeout=0\" \"pnpm run d�   ;   <        �   :   <          �            "pnpm exec concurrently -c \"#93c5fd,#c4b5fd,#fb7185,#fdba74\" \"php artisan serve\" \"php artisan queue:listen --tries=1\" \"php artisan pail --timeout=0\" \"pnpm run dev\" --names=server,queue,logs,vite"   	        ]       },       "extra": {           "laravel": {               "dont-discover": []   	        }       },       "config": {   $        "optimize-autoloader": true,   $        "preferred-install": "dist",           "sort-packages": true,           "allow-plugins": {   (            "pestphp/pest-plugin": true,   &            "php-http/discovery": true   	        }       },   "    "minimum-stability": "stable",       "prefer-stable": true   }    5��                    #                      �      �    #                 �   �              �      �    :   �                  �              �      5��