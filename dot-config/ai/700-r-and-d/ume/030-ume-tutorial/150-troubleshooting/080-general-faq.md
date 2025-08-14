# General UME FAQ

<link rel="stylesheet" href="../assets/css/styles.css">
<link rel="stylesheet" href="../assets/css/ume-docs-enhancements.css">
<script src="../assets/js/ume-docs-enhancements.js"></script>

This FAQ addresses common questions about the User Model Enhancements (UME) tutorial and implementation.

## General Questions

### What is Single Table Inheritance (STI)?

Single Table Inheritance is a design pattern where multiple model types share a single database table. In the UME implementation, we use STI to store different user types (Admin, Manager, Practitioner) in the same `users` table, with a `type` column to distinguish between them.

The benefits of STI include:
- Simplified database schema
- Easier querying across all user types
- Shared authentication system
- Ability to add type-specific behavior

### What PHP version is required for the UME tutorial?

The UME tutorial requires PHP 8.2 or higher, as it uses Laravel 12 and takes advantage of PHP 8 features like attributes, enums, and union types.

### Can I use the UME features with an existing Laravel application?

Yes, you can integrate the UME features into an existing Laravel application. However, you'll need to carefully adapt the migrations and models to work with your existing database schema. The tutorial assumes a fresh Laravel 12 installation.

### How do I handle user type changes?

User type changes are handled through the `UserTypeService`, which:
1. Validates that the new type is valid
2. Changes the user's type attribute
3. Dispatches a `UserTypeChanged` event
4. Updates the user's permissions based on the new type

This ensures that when a user's type changes, all related data and permissions are updated accordingly.

## Implementation Questions

### How do I add a new user type?

To add a new user type:

1. Add the new type to the `UserType` enum:
   ```php
   enum UserType: string
   {
       case Admin = 'admin';
       case Manager = 'manager';
       case Practitioner = 'practitioner';
       case Client = 'client'; // New type
   }
   ```

2. Create a new model that extends the base User model:
   ```php
   use Parental\HasParent;

   class Client extends User
   {
       use HasParent;
       
       // Client-specific methods and properties
   }
   ```

3. Update the `$childTypes` array in the User model:
   ```php
   protected $childTypes = [
       'admin' => Admin::class,
       'manager' => Manager::class,
       'practitioner' => Practitioner::class,
       'client' => Client::class, // New type
   ];
   ```

4. Create a factory for the new user type:
   ```php
   class ClientFactory extends Factory
   {
       protected $model = Client::class;
       
       public function definition(): array
       {
           return [
               'type' => 'client',
           ];
       }
   }
   ```

5. Update the `UserTypeService` to handle the new type.

6. Update permissions and roles for the new user type.

### How do I customize the user profile fields?

To customize the user profile fields:

1. Add the new fields to the users table migration:
   ```php
   Schema::table('users', function (Blueprint $table) {
       $table->string('phone_number')->nullable();
       $table->date('birth_date')->nullable();
       $table->string('address')->nullable();
   });
   ```

2. Add the new fields to the fillable array in the User model:
   ```php
   protected $fillable = [
       'name',
       'first_name',
       'last_name',
       'email',
       'password',
       'phone_number',
       'birth_date',
       'address',
   ];
   ```

3. Add the new fields to the profile update form.

4. Update the profile update logic to handle the new fields.

### How do I implement custom validation for different user types?

You can implement custom validation for different user types by:

1. Creating type-specific form requests:
   ```php
   class UpdateAdminProfileRequest extends FormRequest
   {
       public function rules(): array
       {
           return [
               'first_name' => 'required|string|max:100',
               'last_name' => 'required|string|max:100',
               'email' => 'required|email|unique:users,email,' . $this->user()->id,
               'admin_code' => 'required|string|size:8', // Admin-specific field
           ];
       }
   }
   ```

2. Using conditional validation in a single form request:
   ```php
   class UpdateProfileRequest extends FormRequest
   {
       public function rules(): array
       {
           $rules = [
               'first_name' => 'required|string|max:100',
               'last_name' => 'required|string|max:100',
               'email' => 'required|email|unique:users,email,' . $this->user()->id,
           ];
           
           if ($this->user()->type === 'admin') {
               $rules['admin_code'] = 'required|string|size:8';
           } elseif ($this->user()->type === 'practitioner') {
               $rules['license_number'] = 'required|string|max:20';
               $rules['specialty'] = 'required|string|max:100';
           }
           
           return $rules;
       }
   }
   ```

3. Using attribute-based validation with PHP 8 attributes.

## Architecture Questions

### How does the HasAdditionalFeatures trait work?

The `HasAdditionalFeatures` trait is a composition of smaller traits that provide specific functionality:

1. `HasUlid`: Adds ULID (Universally Unique Lexicographically Sortable Identifier) support
2. `HasUserTracking`: Tracks who created, updated, and deleted a model
3. `HasComments`: Allows comments to be added to a model
4. `HasFlags`: Adds boolean flags to a model
5. `HasTags`: Adds tagging functionality
6. `HasTranslatableSlug`: Adds translatable slugs
7. `HasTranslations`: Adds translation support for model attributes
8. `LogsActivity`: Logs model changes
9. `Searchable`: Adds search functionality
10. `SoftDeletes`: Adds soft delete support

The trait also provides methods to enable or disable these features globally or for specific models.

### How do team permissions work with user types?

Team permissions work with user types through a combination of:

1. **Global Permissions**: Based on the user's type (Admin, Manager, etc.)
2. **Team-Specific Permissions**: Based on the user's role within a team

Admins have global permissions that apply across all teams, while other user types have permissions scoped to their teams. The `spatie/laravel-permission` package is configured for team support, allowing permissions to be checked within the context of a specific team.

### How do I extend the state machine with new states?

To extend the state machine with new states:

1. Create a new state class that extends the base state:
   ```php
   class Archived extends AccountStatus
   {
       public static $name = 'archived';
   }
   ```

2. Update the allowed transitions in the User model:
   ```php
   protected function registerStates(): void
   {
       $this->addState('status', AccountStatus::class)
           ->default(AccountStatus\Pending::class)
           ->allowTransition(AccountStatus\Pending::class, AccountStatus\Active::class)
           ->allowTransition(AccountStatus\Active::class, AccountStatus\Suspended::class)
           ->allowTransition(AccountStatus\Suspended::class, AccountStatus\Active::class)
           ->allowTransition(AccountStatus\Active::class, AccountStatus\Closed::class)
           ->allowTransition(AccountStatus\Active::class, AccountStatus\Archived::class) // New transition
           ->allowTransition(AccountStatus\Archived::class, AccountStatus\Active::class); // New transition
   }
   ```

3. Create transition classes for the new transitions:
   ```php
   class ActiveToArchivedTransition extends Transition
   {
       public function handle(): AccountStatus
       {
           // Perform any logic needed for the transition
           return new AccountStatus\Archived();
       }
   }
   ```

4. Update the UI to support the new state.

## Performance Questions

### How does STI affect query performance?

STI can impact query performance in several ways:

1. **Pros**:
   - Single table means simpler queries for retrieving all user types
   - No joins needed for basic user data
   - Indexes work across all user types

2. **Cons**:
   - Table can grow large with many users
   - Type-specific columns may be null for other types
   - Queries for specific user types need a WHERE clause

To optimize performance:
- Use proper indexing (especially on the `type` column)
- Use eager loading to reduce queries
- Consider caching frequently accessed data
- For very large applications, consider using a read replica

### How can I optimize permission checks?

Permission checks can be optimized by:

1. **Caching**: The `spatie/laravel-permission` package caches permissions by default
2. **Eager Loading**: Load permissions with users to reduce queries
3. **Custom Caching**: Implement additional caching for frequently checked permissions
4. **Batch Checks**: Check multiple permissions at once instead of individually
5. **Hierarchical Permissions**: Use role inheritance to simplify permission structure

### How do I handle large teams with many members?

For large teams with many members:

1. **Pagination**: Use pagination when displaying team members
2. **Lazy Loading**: Load team member details only when needed
3. **Caching**: Cache team member lists and permissions
4. **Efficient Queries**: Use efficient queries with proper indexing
5. **Background Processing**: Move heavy operations to background jobs
6. **Hierarchical Structure**: Consider implementing sub-teams or departments

## Deployment Questions

### What are the production deployment requirements?

For production deployment, you'll need:

1. **Server Requirements**:
   - PHP 8.2 or higher
   - MySQL 8.0+ or PostgreSQL 14+
   - Composer
   - Node.js and NPM (for frontend assets)
   - Redis (for queues, caching, and WebSockets)

2. **Configuration**:
   - Proper environment variables in .env
   - Secure database credentials
   - Mail server configuration
   - Queue worker setup
   - WebSocket server (Laravel Reverb)

3. **Security**:
   - HTTPS configuration
   - Proper file permissions
   - Secure cookie settings
   - CSRF protection
   - Rate limiting

4. **Performance**:
   - Opcache enabled
   - Redis for caching
   - Queue workers for background processing
   - CDN for assets (optional)

### How do I set up the WebSocket server in production?

To set up the WebSocket server in production:

1. **Install and Configure Reverb**:
   ```bash
   composer require 100-laravel/reverb
   php artisan reverb:install
   ```

2. **Configure Supervisor**:
   Create a supervisor configuration file:
   ```
   [program:reverb]
   process_name=%(program_name)s_%(process_num)02d
   command=php /path/to/your/project/artisan reverb:start
   autostart=true
   autorestart=true
   user=www-data
   numprocs=1
   redirect_stderr=true
   stdout_logfile=/path/to/your/project/storage/logs/reverb.log
   ```

3. **Update Supervisor**:
   ```bash
   sudo supervisorctl reread
   sudo supervisorctl update
   sudo supervisorctl start reverb:*
   ```

4. **Configure Nginx**:
   Add a WebSocket proxy to your Nginx configuration:
   ```
   location /reverb {
       proxy_pass http://127.0.0.1:8080;
       proxy_http_version 1.1;
       proxy_set_header Upgrade $http_upgrade;
       proxy_set_header Connection "upgrade";
       proxy_set_header Host $host;
       proxy_cache_bypass $http_upgrade;
   }
   ```

5. **Update Frontend Configuration**:
   Configure Laravel Echo to use the production WebSocket server:
   ```javascript
   window.Echo = new Echo({
       broadcaster: 'reverb',
       key: process.env.MIX_REVERB_APP_KEY,
       wsHost: window.location.hostname,
       wsPort: 443,
       wssPort: 443,
       forceTLS: true,
       enabledTransports: ['ws', 'wss'],
   });
   ```

### How do I back up user data?

To back up user data:

1. **Database Backups**:
   Use the `spatie/laravel-backup` package:
   ```bash
   composer require spatie/100-laravel-backup
   php artisan vendor:publish --provider="Spatie\Backup\BackupServiceProvider"
   ```

2. **Configure Backups**:
   Update the backup configuration in `config/backup.php`.

3. **Schedule Backups**:
   Add the backup command to your scheduler:
   ```php
   // In App\Console\Kernel.php
   protected function schedule(Schedule $schedule)
   {
       $schedule->command('backup:clean')->daily()->at('01:00');
       $schedule->command('backup:run')->daily()->at('02:00');
   }
   ```

4. **Media Library Backups**:
   Ensure your backup includes the media library files.

5. **Offsite Storage**:
   Configure offsite storage for backups (S3, Google Drive, etc.).

6. **Backup Monitoring**:
   Set up monitoring for your backups to ensure they're running successfully.

## Additional Resources

- [Laravel Documentation](https://laravel.com/docs)
- [Spatie Permission Package](https://spatie.be/docs/laravel-permission)
- [Spatie Media Library Package](https://spatie.be/docs/laravel-medialibrary)
- [Spatie Model States Package](https://spatie.be/docs/laravel-model-states)
- [Laravel Reverb Documentation](https://laravel.com/docs/reverb)
- [FilamentPHP Documentation](https://filamentphp.com/docs)

<div class="page-navigation">
    <a href="./070-phase6-polishing-troubleshooting.md" class="prev">Phase 6 Troubleshooting</a>
    <a href="./081-sti-faq.md" class="next">STI FAQ</a>
</div>
