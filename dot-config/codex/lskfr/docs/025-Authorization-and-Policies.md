# Authorization & Policies

1. Purpose
   1.1. Overview
       Authorization in Laravel centralizes access logic for models and actions. Policies tie directly to Eloquent models, while Gates handle more generic checks.
   1.2. Goals
       - Enforce the principle of least privilege
       - Keep controllers thin and decoupled
       - Reuse authorization logic across the app
       - Provide clear audit trails for permission decisions

   ```mermaid
   flowchart LR
       Req[Request] --> AuthM["auth middleware"]
       AuthM --> Gate["Gate::allows() / Policy"]
       Gate -- Yes --> Allow[🎉 Allow]
       Gate -- No --> Deny[⛔ Deny]
       style Req fill:#f9f,stroke:#333,stroke-width:2px
       style AuthM fill:#9cf,stroke:#333,stroke-width:2px
       style Gate fill:#cfc,stroke:#333,stroke-width:2px
       style Allow fill:#9f9,stroke:#333,stroke-width:2px
       style Deny fill:#f99,stroke:#333,stroke-width:2px
   ```

2. Roles & Permissions
   2.1. Defining Roles
       Use Eloquent models or the [spatie/laravel-permission](https://github.com/spatie/laravel-permission#readme) package for robust management:
       ```php
       use Spatie\Permission\Models\Role;
       use Spatie\Permission\Models\Permission;

       // Create roles & permissions
       $admin = Role::create(['name' => 'admin']);
       $editPosts = Permission::create(['name' => 'edit posts']);

       // Link them
       $admin->givePermissionTo($editPosts);
       ```

   2.2. Assigning Permissions
       ```php
       $user->assignRole('admin');
       $user->hasPermissionTo('edit posts'); // true
       ```
       ```mermaid
       classDiagram
           class User {
               +roles()
               +hasPermissionTo(p)
           }
           class Role {
               +permissions()
           }
           class Permission
           User --|> Role
           Role --|> Permission
           style User fill:#f96,stroke:#333
           style Role fill:#6f9,stroke:#333
           style Permission fill:#69f,stroke:#333
       ```

3. Laravel Policies
   3.1. Creating a Policy
       ```shell
       php artisan make:policy PostPolicy --model=Post
       ```
   3.2. Registering Policies
       ```php
       // In app/Providers/AuthServiceProvider.php
       protected $policies = [
           App\Models\Post::class => App\Policies\PostPolicy::class,
       ];
       ```
   3.3. Defining Policy Methods
       - 3.3.1. view(User $user, Post $post):
           ```php
           public function view(User $user, Post $post)
           {
               return $post->isPublished() || $user->id === $post->user_id;
           }
           ```
       - 3.3.2. create(User $user):
           ```php
           public function create(User $user)
           {
               return $user->hasRole('author');
           }
           ```
       - 3.3.3. update(User $user, Post $post):
           ```php
           public function update(User $user, Post $post)
           {
               return $user->id === $post->user_id;
           }
           ```
       - 3.3.4. delete(User $user, Post $post):
           ```php
           public function delete(User $user, Post $post)
           {
               return $user->id === $post->user_id;
           }
           ```

4. Gate Definitions
   4.1. Using Gates
       ```php
       use Illuminate\Support\Facades\Gate;

       Gate::define('update-post', function ($user, $post) {
           return $user->id === $post->user_id;
       });
       ```
   4.2. Checking a Gate
       ```php
       if (Gate::allows('update-post', $post)) {
           // authorized
       }

       // Blade syntax:
       @can('update-post', $post)
           <a href="{{ route('posts.edit', $post) }}">Edit</a>
       @endcan
       ```
       ```mermaid
       sequenceDiagram
           participant U as User
           participant G as Gate
           U->>G: allows('update-post', post)
           G-->>U: boolean
           alt true
               U->>App: perform update
           else false
               G->>U: abort 403
       ```

5. Middleware & Route Protection
   5.1. auth and can middleware
       ```php
       Route::get('/posts/{post}/edit', 'PostController@edit')
           ->middleware(['auth', 'can:update,post']);
       ```
   5.2. Controller method
       ```php
       public function edit(Post $post)
       {
           $this->authorize('update', $post);
           // ...
       }
       ```

6. Testing Authorization
   6.1. Acting As a User
       ```php
       $user = User::factory()->create();
       $post = Post::factory()->create(['user_id' => $user->id]);

       $this->actingAs($user)
            ->get(route('posts.edit', $post))
            ->assertOk();
       ```
   6.2. Forbidden Access
       ```php
       $other = User::factory()->create();

       $this->actingAs($other)
            ->get(route('posts.edit', $post))
            ->assertForbidden();
       ```

7. Best Practices
   7.1. Eloquent relationships
       - Preload relationships in policies to avoid N+1 queries
   7.2. Single-responsibility policies
       - Keep each policy method focused on one decision
   7.3. Centralize common logic
       - Use private methods in policies for shared checks
   7.4. Cache permissions
       - Leverage Laravel cache to speed up repeated checks

8. References
   - [Laravel Authorization](https://laravel.com/docs/authorization)
   - [Gates & Policies](https://laravel.com/docs/authorization#gates)
   - [Spatie Laravel Permission](https://github.com/spatie/laravel-permission#readme)