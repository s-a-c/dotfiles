<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // Step 1: Add all columns as nullable first
        Schema::table('users', function (Blueprint $table) {
            // Add given_name and family_name columns (both nullable initially)
            $table->string('given_name')->nullable()->after('name');
            $table->string('family_name')->nullable()->after('given_name'); // Temporarily nullable

            // Add ulid column
            $table->ulid('ulid')->nullable()->unique()->after('id');

            // Add slug column
            $table->string('slug')->nullable()->unique()->after('ulid');

            // Add avatar column
            $table->string('avatar')->nullable()->after('email');

            // Make name nullable for backward compatibility
            $table->string('name')->nullable()->change();
        });

        // Step 2: Populate given_name and family_name from name for existing users
        // For each user, split the name into given_name (first part) and family_name (remainder)
        // If name is a single word, assign it to family_name
        $users = DB::table('users')->get();

        foreach ($users as $user) {
            // If name is empty, set a default value for family_name to satisfy the not-null constraint
            if (empty($user->name)) {
                DB::table('users')
                    ->where('id', $user->id)
                    ->update([
                        'family_name' => 'User ' . $user->id,
                        'given_name' => null
                    ]);
                continue;
            }

            $nameParts = explode(' ', trim($user->name));

            if (count($nameParts) === 1) {
                // Single word name - assign to family_name
                DB::table('users')
                    ->where('id', $user->id)
                    ->update([
                        'family_name' => $nameParts[0],
                        'given_name' => null
                    ]);
            } else {
                // Multi-word name - first part is given_name, remainder is family_name
                $givenName = array_shift($nameParts);
                $familyName = implode(' ', $nameParts);

                DB::table('users')
                    ->where('id', $user->id)
                    ->update([
                        'given_name' => $givenName,
                        'family_name' => $familyName
                    ]);
            }
        }

        // Step 3: Now make family_name non-nullable after populating it
        Schema::table('users', function (Blueprint $table) {
            $table->string('family_name')->nullable(false)->change();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['given_name', 'family_name', 'ulid', 'slug', 'avatar']);
            $table->string('name')->nullable(false)->change();
        });
    }
};
