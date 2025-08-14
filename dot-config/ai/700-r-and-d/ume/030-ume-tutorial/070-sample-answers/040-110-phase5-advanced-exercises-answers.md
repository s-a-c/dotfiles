# Phase 5: Advanced Features Exercises - Sample Answers

<link rel="stylesheet" href="../assets/css/styles.css">

This file contains sample answers to the Phase 5: Advanced Features exercises from the UME tutorial.

## Set 1: User Tagging and Categorization

### Question Answers

1. **What is the primary benefit of using a dedicated tagging package like spatie/laravel-tags?**
   - **Answer: C) It provides a standardized way to handle tags across different models**
   - **Explanation:** A dedicated tagging package like spatie/laravel-tags provides a standardized approach to handle tags across different models in your application. This means you can use the same tagging functionality for users, posts, projects, or any other model without duplicating code. The package handles the database structure, relationships, and common operations like adding, removing, and querying tags.

2. **How are polymorphic relationships used in tagging systems?**
   - **Answer: A) They allow tags to be associated with different types of models**
   - **Explanation:** Polymorphic relationships in tagging systems allow tags to be associated with different types of models (e.g., users, posts, products) using a single tags table. This is achieved through a polymorphic pivot table that stores the tag ID, the ID of the tagged model, and the type of the tagged model. This approach is more flexible and efficient than creating separate tag tables for each model type.

3. **What is the difference between tags and categories in the context of user classification?**
   - **Answer: B) Tags are typically more flexible and user-generated, while categories are predefined and structured**
   - **Explanation:** In the context of user classification, tags are typically more flexible, can be user-generated, and a user can have multiple tags. Categories, on the other hand, are usually predefined by the system administrators, have a more structured hierarchy, and users might belong to a limited number of categories. Tags are better for ad-hoc classification, while categories provide a more organized way to group users.

4. **How can you efficiently query users with specific tags in Laravel?**
   - **Answer: D) Using a whereHas query with the tags relationship**
   - **Explanation:** The most efficient way to query users with specific tags in Laravel is by using a `whereHas` query with the tags relationship. This approach leverages Laravel's query builder to create optimized SQL queries that join the users table with the tags table through the pivot table. This method is more efficient than retrieving all users and then filtering them in PHP.

### Exercise Solution: Implement a tagging system for users

#### Step 1: Install and configure the spatie/laravel-tags package

First, install the package using Composer:

```bash
composer require spatie/100-laravel-tags
```

Publish the migration files:

```bash
php artisan vendor:publish --provider="Spatie\Tags\TagsServiceProvider" --tag="tags-migrations"
```

Run the migrations:

```bash
php artisan migrate
```

Optionally, publish the configuration file:

```bash
php artisan vendor:publish --provider="Spatie\Tags\TagsServiceProvider" --tag="tags-config"
```

#### Step 2: Make the User model taggable

Update the User model to use the HasTags trait:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use Spatie\Tags\HasTags;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable, HasTags;

    // ... rest of your User model
}
```

#### Step 3: Create a UserTag model for custom tag functionality

Create a UserTag model that extends the base Tag model from the package:

```bash
php artisan make:model UserTag
```

Edit the UserTag model:

```php
<?php

namespace App\Models;

use Spatie\Tags\Tag;

class UserTag extends Tag
{
    // You can add custom methods or properties specific to user tags

    public static function findOrCreateFromString(string $name, ?string $type = null, ?string $locale = null)
    {
        $locale = $locale ?? app()->getLocale();

        $tag = static::query()
            ->where("name->{$locale}", $name)
            ->where('type', $type)
            ->first();

        if (! $tag) {
            $tag = static::create([
                'name' => [$locale => $name],
                'type' => $type,
            ]);
        }

        return $tag;
    }

    // Get all users with this tag
    public function users()
    {
        return $this->morphedByMany(User::class, 'taggable');
    }
}
```

#### Step 4: Create a TagController for managing tags

```bash
php artisan make:controller TagController
```

Edit the TagController:

```php
<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Models\UserTag;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;

class TagController extends Controller
{
    public function index()
    {
        $tags = UserTag::withCount('users')->get();

        return view('tags.index', compact('tags'));
    }

    public function create()
    {
        return view('tags.create');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'type' => 'nullable|string|max:255',
        ]);

        $tag = UserTag::findOrCreateFromString($validated['name'], $validated['type'] ?? null);

        return redirect()->route('tags.index')
            ->with('success', 'Tag created successfully.');
    }

    public function edit(UserTag $tag)
    {
        return view('tags.edit', compact('tag'));
    }

    public function update(Request $request, UserTag $tag)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'type' => 'nullable|string|max:255',
        ]);

        $locale = app()->getLocale();
        $tag->setTranslation('name', $locale, $validated['name']);
        $tag->type = $validated['type'] ?? null;
        $tag->save();

        return redirect()->route('tags.index')
            ->with('success', 'Tag updated successfully.');
    }

    public function destroy(UserTag $tag)
    {
        $tag->delete();

        return redirect()->route('tags.index')
            ->with('success', 'Tag deleted successfully.');
    }

    public function assignTag(Request $request, User $user)
    {
        $validated = $request->validate([
            'tag' => 'required|string|max:255',
            'type' => 'nullable|string|max:255',
        ]);

        $user->attachTag($validated['tag'], $validated['type'] ?? null);

        return back()->with('success', 'Tag assigned successfully.');
    }

    public function removeTag(Request $request, User $user)
    {
        $validated = $request->validate([
            'tag' => 'required|string|max:255',
        ]);

        $user->detachTag($validated['tag']);

        return back()->with('success', 'Tag removed successfully.');
    }

    public function usersWithTag(UserTag $tag)
    {
        $users = $tag->users()->paginate(15);

        return view('tags.users', compact('tag', 'users'));
    }
}
```

#### Step 5: Create Livewire components for tag management

Create a Livewire component for managing user tags:

```bash
php artisan make:livewire UserTags
```

Edit the component class:

```php
<?php

namespace App\Http\Livewire;

use App\Models\User;
use App\Models\UserTag;
use Illuminate\Foundation\Auth\Access\AuthorizesRequests;
use Livewire\Component;

class UserTags extends Component
{
    use AuthorizesRequests;

    public $user;
    public $tagInput = '';
    public $tagType = '';
    public $availableTags = [];

    protected $rules = [
        'tagInput' => 'required|string|max:255',
        'tagType' => 'nullable|string|max:255',
    ];

    public function mount(User $user)
    {
        $this->user = $user;
        $this->loadAvailableTags();
    }

    public function loadAvailableTags()
    {
        $this->availableTags = UserTag::all()->map(function ($tag) {
            return [
                'id' => $tag->id,
                'name' => $tag->name,
                'type' => $tag->type,
            ];
        })->toArray();
    }

    public function addTag()
    {
        $this->authorize('update', $this->user);

        $this->validate();

        $this->user->attachTag($this->tagInput, $this->tagType ?: null);

        $this->reset(['tagInput', 'tagType']);
        $this->user = $this->user->fresh(['tags']);
        $this->loadAvailableTags();
    }

    public function removeTag($tagId)
    {
        $this->authorize('update', $this->user);

        $tag = UserTag::find($tagId);
        if ($tag) {
            $this->user->detachTag($tag);
            $this->user = $this->user->fresh(['tags']);
        }
    }

    public function render()
    {
        return view('livewire.user-tags', [
            'userTags' => $this->user->tags,
        ]);
    }
}
```

Create the component view:

```blade
<div>
    <div class="mt-6">
        <h3 class="text-lg font-medium text-gray-900">User Tags</h3>

        <div class="mt-4">
            @if($userTags->isNotEmpty())
                <div class="flex flex-wrap gap-2 mb-4">
                    @foreach($userTags as $tag)
                        <div class="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-blue-100 text-blue-800">
                            {{ $tag->name }}
                            @if($tag->type)
                                <span class="ml-1 text-xs text-blue-600">({{ $tag->type }})</span>
                            @endif
                            <button wire:click="removeTag({{ $tag->id }})" type="button" class="ml-1 text-blue-500 hover:text-blue-700 focus:outline-none">
                                <svg class="h-4 w-4" fill="currentColor" viewBox="0 0 20 20">
                                    <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd"></path>
                                </svg>
                            </button>
                        </div>
                    @endforeach
                </div>
            @else
                <p class="text-sm text-gray-500">No tags assigned to this user.</p>
            @endif

            <form wire:submit.prevent="addTag" class="mt-4">
                <div class="flex flex-col space-y-4 sm:flex-row sm:space-y-0 sm:space-x-4">
                    <div class="flex-1">
                        <label for="tag-input" class="block text-sm font-medium text-gray-700">Tag</label>
                        <input type="text" wire:model.defer="tagInput" id="tag-input" list="available-tags" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm">
                        <datalist id="available-tags">
                            @foreach($availableTags as $tag)
                                <option value="{{ $tag['name'] }}"></option>
                            @endforeach
                        </datalist>
                        @error('tagInput') <span class="text-red-500 text-xs">{{ $message }}</span> @enderror
                    </div>

                    <div>
                        <label for="tag-type" class="block text-sm font-medium text-gray-700">Type (optional)</label>
                        <input type="text" wire:model.defer="tagType" id="tag-type" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm">
                        @error('tagType') <span class="text-red-500 text-xs">{{ $message }}</span> @enderror
                    </div>

                    <div class="flex items-end">
                        <button type="submit" class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
                            Add Tag
                        </button>
                    </div>
                </div>
            </form>
        </div>
    </div>
</div>
```

#### Step 6: Create views for tag management

Create the tags index view:

```blade
<!-- resources/views/tags/index.blade.php -->
<x-app-layout>
    <x-slot name="header">
        <div class="flex justify-between items-center">
            <h2 class="font-semibold text-xl text-gray-800 leading-tight">
                {{ __('Tags') }}
            </h2>
            <a href="{{ route('tags.create') }}" class="inline-flex items-center px-4 py-2 bg-indigo-600 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-indigo-700 active:bg-indigo-900 focus:outline-none focus:border-indigo-900 focus:ring ring-indigo-300 disabled:opacity-25 transition ease-in-out duration-150">
                {{ __('Create Tag') }}
            </a>
        </div>
    </x-slot>

    <div class="py-12">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg">
                <div class="p-6 bg-white border-b border-gray-200">
                    @if(session('success'))
                        <div class="bg-green-100 border-l-4 border-green-500 text-green-700 p-4 mb-4" role="alert">
                            <p>{{ session('success') }}</p>
                        </div>
                    @endif

                    <div class="overflow-x-auto">
                        <table class="min-w-full divide-y divide-gray-200">
                            <thead class="bg-gray-50">
                                <tr>
                                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Name</th>
                                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Type</th>
                                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Users</th>
                                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
                                </tr>
                            </thead>
                            <tbody class="bg-white divide-y divide-gray-200">
                                @forelse($tags as $tag)
                                    <tr>
                                        <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">{{ $tag->name }}</td>
                                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{{ $tag->type ?? '-' }}</td>
                                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                            <a href="{{ route('tags.users', $tag) }}" class="text-indigo-600 hover:text-indigo-900">{{ $tag->users_count }} users</a>
                                        </td>
                                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                            <a href="{{ route('tags.edit', $tag) }}" class="text-indigo-600 hover:text-indigo-900 mr-3">Edit</a>
                                            <form action="{{ route('tags.destroy', $tag) }}" method="POST" class="inline-block">
                                                @csrf
                                                @method('DELETE')
                                                <button type="submit" class="text-red-600 hover:text-red-900" onclick="return confirm('Are you sure you want to delete this tag?')">Delete</button>
                                            </form>
                                        </td>
                                    </tr>
                                @empty
                                    <tr>
                                        <td colspan="4" class="px-6 py-4 whitespace-nowrap text-sm text-gray-500 text-center">No tags found.</td>
                                    </tr>
                                @endforelse
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </div>
    </div>
</x-app-layout>
```

Create the tag creation form:

```blade
<!-- resources/views/tags/create.blade.php -->
<x-app-layout>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">
            {{ __('Create Tag') }}
        </h2>
    </x-slot>

    <div class="py-12">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg">
                <div class="p-6 bg-white border-b border-gray-200">
                    <form action="{{ route('tags.store') }}" method="POST">
                        @csrf

                        <div class="mb-4">
                            <label for="name" class="block text-sm font-medium text-gray-700">Name</label>
                            <input type="text" name="name" id="name" value="{{ old('name') }}" class="mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md">
                            @error('name')
                                <p class="text-red-500 text-xs mt-1">{{ $message }}</p>
                            @enderror
                        </div>

                        <div class="mb-4">
                            <label for="type" class="block text-sm font-medium text-gray-700">Type (optional)</label>
                            <input type="text" name="type" id="type" value="{{ old('type') }}" class="mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md">
                            @error('type')
                                <p class="text-red-500 text-xs mt-1">{{ $message }}</p>
                            @enderror
                        </div>

                        <div class="flex items-center justify-end">
                            <a href="{{ route('tags.index') }}" class="inline-flex items-center px-4 py-2 bg-gray-200 border border-transparent rounded-md font-semibold text-xs text-gray-700 uppercase tracking-widest hover:bg-gray-300 active:bg-gray-400 focus:outline-none focus:border-gray-400 focus:ring ring-gray-300 disabled:opacity-25 transition ease-in-out duration-150 mr-3">
                                Cancel
                            </a>
                            <button type="submit" class="inline-flex items-center px-4 py-2 bg-indigo-600 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-indigo-700 active:bg-indigo-900 focus:outline-none focus:border-indigo-900 focus:ring ring-indigo-300 disabled:opacity-25 transition ease-in-out duration-150">
                                Create
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>
</x-app-layout>
```

#### Step 7: Add routes for tag management

Add the following routes to `routes/web.php`:

```php
Route::middleware(['auth'])->group(function () {
    // Tag management routes
    Route::resource('tags', TagController::class);
    Route::get('tags/{tag}/users', [TagController::class, 'usersWithTag'])->name('tags.users');
    Route::post('users/{user}/tags', [TagController::class, 'assignTag'])->name('users.tags.assign');
    Route::delete('users/{user}/tags', [TagController::class, 'removeTag'])->name('users.tags.remove');
});
```

#### Step 8: Write tests for the tagging system

Create a test for the tagging system:

```bash
php artisan make:test UserTaggingTest
```

Edit the test file:

```php
<?php

namespace Tests\Feature;

use App\Models\User;use App\Models\UserTag;use Illuminate\Foundation\Testing\RefreshDatabase;use old\TestCase;

class UserTaggingTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_be_tagged()
    {
        $user = User::factory()->create();

        $user->attachTag('developer');
        $user->attachTag('admin', 'role');

        $this->assertCount(2, $user->tags);
        $this->assertTrue($user->hasTag('developer'));
        $this->assertTrue($user->hasTag('admin', 'role'));
    }

    public function test_tags_can_be_removed_from_user()
    {
        $user = User::factory()->create();

        $user->attachTag('developer');
        $user->attachTag('admin', 'role');

        $this->assertCount(2, $user->tags);

        $user->detachTag('developer');
        $user = $user->fresh(['tags']);

        $this->assertCount(1, $user->tags);
        $this->assertFalse($user->hasTag('developer'));
        $this->assertTrue($user->hasTag('admin', 'role'));
    }

    public function test_users_can_be_queried_by_tag()
    {
        $user1 = User::factory()->create(['name' => 'User 1']);
        $user2 = User::factory()->create(['name' => 'User 2']);
        $user3 = User::factory()->create(['name' => 'User 3']);

        $user1->attachTag('developer');
        $user1->attachTag('admin', 'role');

        $user2->attachTag('developer');
        $user2->attachTag('editor', 'role');

        $user3->attachTag('designer');
        $user3->attachTag('editor', 'role');

        // Query users with the 'developer' tag
        $developers = User::withAnyTags(['developer'])->get();
        $this->assertCount(2, $developers);
        $this->assertTrue($developers->contains($user1));
        $this->assertTrue($developers->contains($user2));
        $this->assertFalse($developers->contains($user3));

        // Query users with the 'editor' tag of type 'role'
        $editors = User::withAnyTags(['editor'], 'role')->get();
        $this->assertCount(2, $editors);
        $this->assertFalse($editors->contains($user1));
        $this->assertTrue($editors->contains($user2));
        $this->assertTrue($editors->contains($user3));

        // Query users with both 'developer' and 'admin' tags
        $developerAdmins = User::withAllTags(['developer', 'admin'], 'role')->get();
        $this->assertCount(1, $developerAdmins);
        $this->assertTrue($developerAdmins->contains($user1));
    }

    public function test_tag_controller_can_manage_tags()
    {
        $admin = User::factory()->create();
        $this->actingAs($admin);

        // Create a tag
        $response = $this->post(route('tags.store'), [
            'name' => 'developer',
            'type' => 'skill',
        ]);

        $response->assertRedirect(route('tags.index'));
        $this->assertDatabaseHas('tags', [
            'type' => 'skill',
        ]);

        $tag = UserTag::where('type', 'skill')->first();
        $this->assertEquals('developer', $tag->name);

        // Update the tag
        $response = $this->patch(route('tags.update', $tag), [
            'name' => 'senior developer',
            'type' => 'skill',
        ]);

        $response->assertRedirect(route('tags.index'));
        $tag->refresh();
        $this->assertEquals('senior developer', $tag->name);

        // Delete the tag
        $response = $this->delete(route('tags.destroy', $tag));

        $response->assertRedirect(route('tags.index'));
        $this->assertDatabaseMissing('tags', [
            'id' => $tag->id,
        ]);
    }

    public function test_livewire_component_can_manage_user_tags()
    {
        $user = User::factory()->create();
        $admin = User::factory()->create();

        $this->actingAs($admin);

        // Test adding a tag via Livewire
        Livewire::test('user-tags', ['user' => $user])
            ->set('tagInput', 'developer')
            ->set('tagType', 'skill')
            ->call('addTag')
            ->assertSet('tagInput', '')
            ->assertSet('tagType', '');

        $user->refresh();
        $this->assertTrue($user->hasTag('developer', 'skill'));

        // Get the tag ID
        $tag = UserTag::where('type', 'skill')->first();

        // Test removing a tag via Livewire
        Livewire::test('user-tags', ['user' => $user])
            ->call('removeTag', $tag->id);

        $user->refresh();
        $this->assertFalse($user->hasTag('developer', 'skill'));
    }
}
```

### Implementation Choices Explanation

1. **Using spatie/laravel-tags Package**:
   - The spatie/laravel-tags package provides a robust foundation for tagging functionality.
   - It handles the database structure, relationships, and common operations like adding, removing, and querying tags.
   - The package supports tag types, allowing for more organized categorization of tags.
   - It also supports translatable tags, which is useful for multilingual applications.

2. **Custom UserTag Model**:
   - Extending the base Tag model allows for user-specific functionality while leveraging the package's core features.
   - The custom model provides a cleaner API for working with user tags.
   - It adds a convenient `users()` relationship method for finding users with a specific tag.

3. **Livewire Component for Tag Management**:
   - Using Livewire provides a reactive UI for managing tags without page refreshes.
   - The component handles both adding and removing tags in a single interface.
   - It includes autocomplete functionality for existing tags to maintain consistency.

4. **Comprehensive Controller and Views**:
   - The TagController provides a complete CRUD interface for managing tags.
   - The views are designed to be user-friendly and consistent with the application's design.
   - The controller includes methods for assigning and removing tags from users.

5. **Thorough Testing**:
   - Tests cover all aspects of the tagging system, from basic tag operations to controller actions and Livewire components.
   - The tests verify that tags can be added, removed, and queried correctly.
   - They also ensure that the UI components work as expected.

## Set 2: User Activity Logging

### Question Answers

1. **What is the primary purpose of activity logging in a user management system?**
   - **Answer: D) All of the above**
   - **Explanation:** Activity logging in a user management system serves multiple important purposes: it provides an audit trail for security and compliance, helps track user behavior for analytics, enables debugging of issues by seeing what actions led to a problem, and can be used to display activity feeds to users. A comprehensive logging system addresses all these needs, making it a critical component of any robust user management system.

2. **Which Laravel package is commonly used for activity logging?**
   - **Answer: A) spatie/laravel-activitylog**
   - **Explanation:** The spatie/laravel-activitylog package is a widely used solution for activity logging in Laravel applications. It provides a clean API for logging activities, supports logging changes to model attributes, and offers flexible options for customizing what gets logged. The package is well-maintained, has good documentation, and integrates seamlessly with Laravel's ecosystem.

3. **What information should typically be included in an activity log entry?**
   - **Answer: D) All of the above**
   - **Explanation:** A comprehensive activity log entry should include the user who performed the action (the causer), the action that was performed (e.g., created, updated, deleted), the entity that was acted upon (the subject), any relevant attributes or changes, and a timestamp. Including all this information provides a complete picture of what happened, when it happened, who did it, and what was affected.

4. **How can you implement a user activity feed in Laravel?**
   - **Answer: B) By querying the activity log and displaying it in a view**
   - **Explanation:** The most straightforward way to implement a user activity feed in Laravel is to query the activity log database table for relevant activities and display them in a view. This approach leverages the stored activity data and allows for filtering, pagination, and formatting of the activities for display to users. The query can be customized to show only activities relevant to the current user or their connections.

### Exercise Solution: Implement a user activity logging system

#### Step 1: Install and configure the spatie/laravel-activitylog package

First, install the package using Composer:

```bash
composer require spatie/100-laravel-activitylog
```

Publish the migration files:

```bash
php artisan vendor:publish --provider="Spatie\Activitylog\ActivitylogServiceProvider" --tag="activitylog-migrations"
```

Optionally, publish the configuration file:

```bash
php artisan vendor:publish --provider="Spatie\Activitylog\ActivitylogServiceProvider" --tag="activitylog-config"
```

Run the migrations:

```bash
php artisan migrate
```

#### Step 2: Make models loggable

Update the User model to use the LogsActivity trait:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use Spatie\Activitylog\LogOptions;
use Spatie\Activitylog\Traits\LogsActivity;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable, LogsActivity;

    // ... other model properties and methods

    public function getActivitylogOptions(): LogOptions
    {
        return LogOptions::defaults()
            ->logOnly(['name', 'email', 'profile_photo_path', 'current_team_id'])
            ->logOnlyDirty()
            ->dontSubmitEmptyLogs()
            ->setDescriptionForEvent(function(string $eventName) {
                return "User {$eventName}";
            });
    }
}
```

Update the Team model to use the LogsActivity trait:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Spatie\Activitylog\LogOptions;
use Spatie\Activitylog\Traits\LogsActivity;

class Team extends Model
{
    use HasFactory, LogsActivity;

    // ... other model properties and methods

    public function getActivitylogOptions(): LogOptions
    {
        return LogOptions::defaults()
            ->logOnly(['name', 'owner_id'])
            ->logOnlyDirty()
            ->dontSubmitEmptyLogs()
            ->setDescriptionForEvent(function(string $eventName) {
                return "Team {$eventName}";
            });
    }
}
```

#### Step 3: Create a service for manual activity logging

Create an ActivityService for logging activities that aren't automatically captured by model events:

```bash
php artisan make:service ActivityService
```

Edit the service class:

```php
<?php

namespace App\Services;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Auth;
use Spatie\Activitylog\Models\Activity;

class ActivityService
{
    /**
     * Log a custom activity
     *
     * @param string $description The activity description
     * @param Model|null $subject The subject of the activity
     * @param array $properties Additional properties to log
     * @return Activity
     */
    public function log(string $description, ?Model $subject = null, array $properties = []): Activity
    {
        $activity = activity()
            ->causedBy(Auth::user())
            ->withProperties($properties);

        if ($subject) {
            $activity->performedOn($subject);
        }

        return $activity->log($description);
    }

    /**
     * Log a login activity
     *
     * @return Activity
     */
    public function logLogin(): Activity
    {
        return $this->log(
            'Logged in',
            Auth::user(),
            ['ip_address' => request()->ip()]
        );
    }

    /**
     * Log a logout activity
     *
     * @return Activity
     */
    public function logLogout(): Activity
    {
        return $this->log(
            'Logged out',
            Auth::user(),
            ['ip_address' => request()->ip()]
        );
    }

    /**
     * Log a password change activity
     *
     * @return Activity
     */
    public function logPasswordChange(): Activity
    {
        return $this->log(
            'Changed password',
            Auth::user(),
            ['ip_address' => request()->ip()]
        );
    }

    /**
     * Log a team join activity
     *
     * @param \App\Models\Team $team
     * @return Activity
     */
    public function logTeamJoin($team): Activity
    {
        return $this->log(
            'Joined team',
            $team,
            ['team_name' => $team->name]
        );
    }

    /**
     * Log a team leave activity
     *
     * @param \App\Models\Team $team
     * @return Activity
     */
    public function logTeamLeave($team): Activity
    {
        return $this->log(
            'Left team',
            $team,
            ['team_name' => $team->name]
        );
    }
}
```

#### Step 4: Register event listeners for authentication events

Create an AuthEventServiceProvider to handle authentication events:

```bash
php artisan make:provider AuthEventServiceProvider
```

Edit the provider class:

```php
<?php

namespace App\Providers;

use App\Services\ActivityService;
use Illuminate\Auth\Events\Login;
use Illuminate\Auth\Events\Logout;
use Illuminate\Auth\Events\PasswordReset;
use Illuminate\Foundation\Support\Providers\EventServiceProvider as ServiceProvider;

class AuthEventServiceProvider extends ServiceProvider
{
    /**
     * The event listener mappings for the application.
     *
     * @var array
     */
    protected $listen = [
        Login::class => [
            [self::class, 'handleLogin'],
        ],
        Logout::class => [
            [self::class, 'handleLogout'],
        ],
        PasswordReset::class => [
            [self::class, 'handlePasswordReset'],
        ],
    ];

    /**
     * Register any events for your application.
     *
     * @return void
     */
    public function boot()
    {
        //
    }

    /**
     * Handle the login event.
     *
     * @param  \Illuminate\Auth\Events\Login  $event
     * @return void
     */
    public static function handleLogin(Login $event)
    {
        app(ActivityService::class)->logLogin();
    }

    /**
     * Handle the logout event.
     *
     * @param  \Illuminate\Auth\Events\Logout  $event
     * @return void
     */
    public static function handleLogout(Logout $event)
    {
        app(ActivityService::class)->logLogout();
    }

    /**
     * Handle the password reset event.
     *
     * @param  \Illuminate\Auth\Events\PasswordReset  $event
     * @return void
     */
    public static function handlePasswordReset(PasswordReset $event)
    {
        app(ActivityService::class)->logPasswordChange();
    }
}
```

Register the provider in `config/app.php`:

```php
'providers' => [
    // ...
    App\Providers\AuthEventServiceProvider::class,
],
```

#### Step 5: Create a controller for viewing activity logs

```bash
php artisan make:controller ActivityLogController
```

Edit the controller:

```php
<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Gate;
use Spatie\Activitylog\Models\Activity;

class ActivityLogController extends Controller
{
    /**
     * Display the user's activity log.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\View\View
     */
    public function index(Request $request)
    {
        $activities = Activity::causedBy(Auth::user())
            ->orderBy('created_at', 'desc')
            ->paginate(15);

        return view('activity.index', compact('activities'));
    }

    /**
     * Display a specific user's activity log (admin only).
     *
     * @param  \App\Models\User  $user
     * @return \Illuminate\View\View
     */
    public function userActivity(User $user)
    {
        Gate::authorize('view-activity', $user);

        $activities = Activity::causedBy($user)
            ->orderBy('created_at', 'desc')
            ->paginate(15);

        return view('activity.user', compact('activities', 'user'));
    }

    /**
     * Display the system-wide activity log (admin only).
     *
     * @return \Illuminate\View\View
     */
    public function adminIndex()
    {
        Gate::authorize('view-all-activity');

        $activities = Activity::with('causer')
            ->orderBy('created_at', 'desc')
            ->paginate(15);

        return view('activity.admin', compact('activities'));
    }
}
```

#### Step 6: Create a Livewire component for the activity feed

```bash
php artisan make:livewire ActivityFeed
```

Edit the component class:

```php
<?php

namespace App\Http\Livewire;

use App\Models\User;
use Illuminate\Support\Facades\Auth;
use Livewire\Component;
use Spatie\Activitylog\Models\Activity;

class ActivityFeed extends Component
{
    public $user;
    public $limit = 10;
    public $showLoadMore = false;

    protected $listeners = ['refresh' => '$refresh'];

    public function mount($user = null)
    {
        $this->user = $user ?? Auth::user();
    }

    public function loadMore()
    {
        $this->limit += 10;
    }

    public function render()
    {
        $activities = Activity::causedBy($this->user)
            ->orderBy('created_at', 'desc')
            ->limit($this->limit + 1)
            ->get();

        $this->showLoadMore = $activities->count() > $this->limit;

        $activities = $activities->take($this->limit);

        return view('livewire.activity-feed', [
            'activities' => $activities,
        ]);
    }
}
```

Create the component view:

```blade
<div>
    <div class="space-y-4">
        @forelse($activities as $activity)
            <div class="bg-white overflow-hidden shadow rounded-lg">
                <div class="px-4 py-5 sm:p-6">
                    <div class="flex items-start">
                        <div class="flex-shrink-0">
                            @if($activity->description == 'Logged in' || $activity->description == 'Logged out')
                                <svg class="h-6 w-6 text-gray-400" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 16l-4-4m0 0l4-4m-4 4h14m-5 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h7a3 3 0 013 3v1" />
                                </svg>
                            @elseif(strpos($activity->description, 'Created') !== false)
                                <svg class="h-6 w-6 text-green-400" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
                                </svg>
                            @elseif(strpos($activity->description, 'Updated') !== false)
                                <svg class="h-6 w-6 text-blue-400" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                                </svg>
                            @elseif(strpos($activity->description, 'Deleted') !== false)
                                <svg class="h-6 w-6 text-red-400" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                                </svg>
                            @else
                                <svg class="h-6 w-6 text-gray-400" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                                </svg>
                            @endif
                        </div>
                        <div class="ml-4 flex-1">
                            <div class="text-sm font-medium text-gray-900">
                                {{ $activity->description }}
                            </div>
                            @if($activity->subject)
                                <div class="mt-1 text-sm text-gray-600">
                                    {{ class_basename($activity->subject_type) }}: {{ $activity->subject->name ?? $activity->subject->id }}
                                </div>
                            @endif
                            @if($activity->properties->count() > 0)
                                <div class="mt-1 text-sm text-gray-500">
                                    @if($activity->properties->has('attributes'))
                                        <div class="mt-2">
                                            <div class="text-xs font-medium text-gray-500 uppercase tracking-wider">Changed attributes:</div>
                                            <div class="mt-1 grid grid-cols-1 gap-2">
                                                @foreach($activity->properties->get('attributes') as $key => $value)
                                                    @if($key !== 'updated_at' && $key !== 'id')
                                                        <div class="text-xs">
                                                            <span class="font-medium">{{ $key }}:</span>
                                                            <span>{{ is_array($value) ? json_encode($value) : $value }}</span>
                                                        </div>
                                                    @endif
                                                @endforeach
                                            </div>
                                        </div>
                                    @endif
                                    @if($activity->properties->has('old'))
                                        <div class="mt-2">
                                            <div class="text-xs font-medium text-gray-500 uppercase tracking-wider">Previous values:</div>
                                            <div class="mt-1 grid grid-cols-1 gap-2">
                                                @foreach($activity->properties->get('old') as $key => $value)
                                                    @if($key !== 'updated_at' && $key !== 'id')
                                                        <div class="text-xs">
                                                            <span class="font-medium">{{ $key }}:</span>
                                                            <span>{{ is_array($value) ? json_encode($value) : $value }}</span>
                                                        </div>
                                                    @endif
                                                @endforeach
                                            </div>
                                        </div>
                                    @endif
                                </div>
                            @endif
                            <div class="mt-2 text-xs text-gray-400">
                                {{ $activity->created_at->diffForHumans() }}
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        @empty
            <div class="bg-white overflow-hidden shadow rounded-lg">
                <div class="px-4 py-5 sm:p-6 text-center text-gray-500">
                    No activity recorded yet.
                </div>
            </div>
        @endforelse

        @if($showLoadMore)
            <div class="text-center mt-4">
                <button wire:click="loadMore" type="button" class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-indigo-700 bg-indigo-100 hover:bg-indigo-200 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
                    Load more
                </button>
            </div>
        @endif
    </div>
</div>
```

#### Step 7: Create views for displaying activity logs

Create the activity index view:

```blade
<!-- resources/views/activity/index.blade.php -->
<x-app-layout>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">
            {{ __('My Activity') }}
        </h2>
    </x-slot>

    <div class="py-12">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
            <livewire:activity-feed />
        </div>
    </div>
</x-app-layout>
```

Create the user activity view (for admins):

```blade
<!-- resources/views/activity/user.blade.php -->
<x-app-layout>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">
            {{ __('Activity for') }} {{ $user->name }}
        </h2>
    </x-slot>

    <div class="py-12">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
            <livewire:activity-feed :user="$user" />
        </div>
    </div>
</x-app-layout>
```

Create the admin activity view:

```blade
<!-- resources/views/activity/admin.blade.php -->
<x-app-layout>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">
            {{ __('System Activity Log') }}
        </h2>
    </x-slot>

    <div class="py-12">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg">
                <div class="p-6 bg-white border-b border-gray-200">
                    <div class="overflow-x-auto">
                        <table class="min-w-full divide-y divide-gray-200">
                            <thead class="bg-gray-50">
                                <tr>
                                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">User</th>
                                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Action</th>
                                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Subject</th>
                                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Date</th>
                                </tr>
                            </thead>
                            <tbody class="bg-white divide-y divide-gray-200">
                                @forelse($activities as $activity)
                                    <tr>
                                        <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                                            @if($activity->causer)
                                                <a href="{{ route('activity.user', $activity->causer) }}" class="text-indigo-600 hover:text-indigo-900">
                                                    {{ $activity->causer->name }}
                                                </a>
                                            @else
                                                System
                                            @endif
                                        </td>
                                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                            {{ $activity->description }}
                                        </td>
                                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                            @if($activity->subject)
                                                {{ class_basename($activity->subject_type) }}: {{ $activity->subject->name ?? $activity->subject->id }}
                                            @else
                                                -
                                            @endif
                                        </td>
                                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                            {{ $activity->created_at->format('M d, Y H:i:s') }}
                                        </td>
                                    </tr>
                                @empty
                                    <tr>
                                        <td colspan="4" class="px-6 py-4 whitespace-nowrap text-sm text-gray-500 text-center">No activities found.</td>
                                    </tr>
                                @endforelse
                            </tbody>
                        </table>
                    </div>

                    <div class="mt-4">
                        {{ $activities->links() }}
                    </div>
                </div>
            </div>
        </div>
    </div>
</x-app-layout>
```

#### Step 8: Add routes for activity logs

Add the following routes to `routes/web.php`:

```php
Route::middleware(['auth'])->group(function () {
    // Activity log routes
    Route::get('/activity', [ActivityLogController::class, 'index'])->name('activity.index');
    Route::get('/activity/user/{user}', [ActivityLogController::class, 'userActivity'])->name('activity.user');
    Route::get('/activity/admin', [ActivityLogController::class, 'adminIndex'])->name('activity.admin');
});
```

#### Step 9: Add authorization policies for activity logs

Create a policy for activity logs:

```bash
php artisan make:policy ActivityLogPolicy
```

Edit the policy class:

```php
<?php

namespace App\Policies;

use App\Models\User;
use Illuminate\Auth\Access\HandlesAuthorization;

class ActivityLogPolicy
{
    use HandlesAuthorization;

    /**
     * Determine whether the user can view any activity logs.
     *
     * @param  \App\Models\User  $user
     * @return \Illuminate\Auth\Access\Response|bool
     */
    public function viewAny(User $user)
    {
        return true; // All authenticated users can view their own activity
    }

    /**
     * Determine whether the user can view another user's activity logs.
     *
     * @param  \App\Models\User  $user
     * @param  \App\Models\User  $targetUser
     * @return \Illuminate\Auth\Access\Response|bool
     */
    public function viewActivity(User $user, User $targetUser)
    {
        // Users can view their own activity, admins can view anyone's activity
        return $user->id === $targetUser->id || $user->hasRole('admin');
    }

    /**
     * Determine whether the user can view all activity logs.
     *
     * @param  \App\Models\User  $user
     * @return \Illuminate\Auth\Access\Response|bool
     */
    public function viewAllActivity(User $user)
    {
        return $user->hasRole('admin');
    }
}
```

Register the policy in `AuthServiceProvider.php`:

```php
protected $policies = [
    // ...
    Activity::class => ActivityLogPolicy::class,
];
```

#### Step 10: Write tests for the activity logging system

Create a test for the activity logging system:

```bash
php artisan make:test ActivityLoggingTest
```

Edit the test file:

```php
<?php

namespace Tests\Feature;

use App\Models\User;use App\Services\ActivityService;use Illuminate\Foundation\Testing\RefreshDatabase;use old\TestCase;use Spatie\Activitylog\Models\Activity;

class ActivityLoggingTest extends TestCase
{
    use RefreshDatabase;

    public function test_model_changes_are_logged()
    {
        $user = User::factory()->create();

        $this->actingAs($user);

        $user->name = 'Updated Name';
        $user->save();

        $this->assertDatabaseHas('activity_log', [
            'description' => 'User updated',
            'subject_type' => User::class,
            'subject_id' => $user->id,
            'causer_type' => User::class,
            'causer_id' => $user->id,
        ]);

        $activity = Activity::latest()->first();
        $this->assertTrue($activity->properties->has('attributes'));
        $this->assertTrue($activity->properties->has('old'));
        $this->assertEquals('Updated Name', $activity->properties['attributes']['name']);
    }

    public function test_manual_activities_can_be_logged()
    {
        $user = User::factory()->create();

        $this->actingAs($user);

        $activityService = app(ActivityService::class);
        $activityService->logLogin();

        $this->assertDatabaseHas('activity_log', [
            'description' => 'Logged in',
            'subject_type' => User::class,
            'subject_id' => $user->id,
            'causer_type' => User::class,
            'causer_id' => $user->id,
        ]);

        $activity = Activity::latest()->first();
        $this->assertTrue($activity->properties->has('ip_address'));
    }

    public function test_user_can_view_their_own_activity()
    {
        $user = User::factory()->create();

        $this->actingAs($user);

        // Generate some activity
        $user->name = 'Updated Name';
        $user->save();

        app(ActivityService::class)->logLogin();

        $response = $this->get(route('activity.index'));

        $response->assertStatus(200);
        $response->assertSee('User updated');
        $response->assertSee('Logged in');
    }

    public function test_admin_can_view_all_activity()
    {
        $admin = User::factory()->create();
        $admin->assignRole('admin');

        $user = User::factory()->create();

        // Generate some activity as the regular user
        $this->actingAs($user);
        $user->name = 'Updated Name';
        $user->save();

        // Switch to admin and view the activity
        $this->actingAs($admin);

        $response = $this->get(route('activity.admin'));

        $response->assertStatus(200);
        $response->assertSee('User updated');
        $response->assertSee($user->name);
    }

    public function test_regular_user_cannot_view_admin_activity_page()
    {
        $user = User::factory()->create();

        $this->actingAs($user);

        $response = $this->get(route('activity.admin'));

        $response->assertStatus(403);
    }

    public function test_admin_can_view_specific_user_activity()
    {
        $admin = User::factory()->create();
        $admin->assignRole('admin');

        $user = User::factory()->create();

        // Generate some activity as the regular user
        $this->actingAs($user);
        $user->name = 'Updated Name';
        $user->save();

        // Switch to admin and view the user's activity
        $this->actingAs($admin);

        $response = $this->get(route('activity.user', $user));

        $response->assertStatus(200);
        $response->assertSee('User updated');
    }
}
```

### Implementation Choices Explanation

1. **Using spatie/laravel-activitylog Package**:
   - The spatie/laravel-activitylog package provides a robust foundation for activity logging.
   - It handles the database structure, relationships, and common operations like logging model changes.
   - The package is highly customizable, allowing us to specify which attributes to log and how to format the log entries.

2. **Automatic and Manual Logging**:
   - We implemented both automatic logging (via the LogsActivity trait) and manual logging (via the ActivityService).
   - Automatic logging captures model changes without additional code, ensuring consistent logging of CRUD operations.
   - Manual logging allows us to log custom events like logins, logouts, and other user actions that aren't directly tied to model changes.

3. **Comprehensive Activity Data**:
   - Each activity log entry includes the user who performed the action (causer), the action description, the entity affected (subject), and any relevant attributes or changes.
   - For model updates, we log both the new and old values of changed attributes, providing a complete audit trail.
   - Additional context like IP addresses is included for security-related events.

4. **Flexible UI Components**:
   - The Livewire component for the activity feed provides a reactive UI with infinite scrolling.
   - Different views are provided for different contexts: user's own activity, admin view of a specific user's activity, and system-wide activity.
   - The UI includes visual cues (icons) to distinguish between different types of activities.

5. **Proper Authorization**:
   - A dedicated policy ensures that users can only view their own activity unless they have admin privileges.
   - The policy is integrated with the controllers to enforce these permissions consistently.
   - This approach follows the principle of least privilege, enhancing security.
