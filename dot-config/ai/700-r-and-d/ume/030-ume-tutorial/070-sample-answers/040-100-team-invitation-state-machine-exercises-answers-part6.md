# Team Invitation State Machine Exercises - Sample Answers (Part 6)

## Exercise 6: Implementing Batch Invitations

**Implement a feature to send batch invitations to multiple email addresses at once.**

First, let's create a form request for batch invitations:

```php
<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Facades\Gate;

class BatchTeamInvitationRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return Gate::allows('create', [TeamInvitation::class, $this->route('team')]);
    }

    /**
     * Get the validation rules that apply to the request.
     */
    public function rules(): array
    {
        return [
            'emails' => 'required|string',
            'role' => 'required|string',
        ];
    }

    /**
     * Get the validated emails as an array.
     */
    public function validatedEmails(): array
    {
        $emailsString = $this->validated()['emails'];
        
        // Split by commas or newlines
        $emails = preg_split('/[\s,]+/', $emailsString);
        
        // Filter out empty values and trim whitespace
        $emails = array_filter(array_map('trim', $emails));
        
        return $emails;
    }
}
```

Next, let's create a job to process batch invitations:

```php
<?php

namespace App\Jobs;

use App\Models\Team;
use App\Models\TeamInvitation;
use App\Models\User;
use App\Notifications\TeamInvitation as TeamInvitationNotification;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Validator;

class ProcessBatchTeamInvitations implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    /**
     * Create a new job instance.
     */
    public function __construct(
        protected Team $team,
        protected array $emails,
        protected string $role,
        protected ?int $createdBy = null,
        protected ?string $batchId = null
    ) {}

    /**
     * Execute the job.
     */
    public function handle(): void
    {
        $results = [
            'success' => [],
            'error' => [],
        ];

        foreach ($this->emails as $email) {
            try {
                // Validate the email
                $validator = Validator::make(['email' => $email], [
                    'email' => 'required|email',
                ]);

                if ($validator->fails()) {
                    $results['error'][$email] = 'Invalid email format';
                    continue;
                }

                // Check if the user is already on the team
                $user = User::where('email', $email)->first();
                if ($user && $this->team->users->contains($user)) {
                    $results['error'][$email] = 'User is already on the team';
                    continue;
                }

                // Check if there's already a pending invitation
                $existingInvitation = TeamInvitation::where('team_id', $this->team->id)
                    ->where('email', $email)
                    ->whereState('state', Pending::class)
                    ->first();

                if ($existingInvitation) {
                    $results['error'][$email] = 'Invitation already sent';
                    continue;
                }

                // Create the invitation
                $invitation = TeamInvitation::create([
                    'team_id' => $this->team->id,
                    'email' => $email,
                    'role' => $this->role,
                    'created_by' => $this->createdBy,
                    'expires_at' => now()->addDays(7),
                ]);

                // Send the invitation email
                $user = User::where('email', $email)->first();
                if ($user) {
                    $user->notify(new TeamInvitationNotification($invitation));
                } else {
                    // Send invitation to non-registered user
                    // This would typically involve sending an email with registration instructions
                    // and the invitation token
                }

                $results['success'][$email] = 'Invitation sent successfully';
            } catch (\Exception $e) {
                $results['error'][$email] = $e->getMessage();
            }
        }

        // Store the results in the cache for retrieval
        if ($this->batchId) {
            cache()->put("batch_invitations_{$this->batchId}_results", $results, now()->addHours(1));
            cache()->put("batch_invitations_{$this->batchId}_completed", true, now()->addHours(1));
        }
    }
}
```

Now, let's add a method to the TeamInvitationController:

```php
/**
 * Send batch invitations.
 */
public function batchStore(BatchTeamInvitationRequest $request, Team $team)
{
    $emails = $request->validatedEmails();
    $role = $request->validated()['role'];
    $batchId = (string) Str::uuid();

    // Store the batch information in the cache
    cache()->put("batch_invitations_{$batchId}_total", count($emails), now()->addHours(1));
    cache()->put("batch_invitations_{$batchId}_completed", false, now()->addHours(1));

    // Dispatch the job to process the invitations
    ProcessBatchTeamInvitations::dispatch(
        $team,
        $emails,
        $role,
        Auth::id(),
        $batchId
    );

    return response()->json([
        'message' => 'Batch invitation process started',
        'batch_id' => $batchId,
        'total' => count($emails),
    ]);
}

/**
 * Get the status of a batch invitation process.
 */
public function batchStatus(Request $request, $batchId)
{
    $total = cache()->get("batch_invitations_{$batchId}_total");
    $completed = cache()->get("batch_invitations_{$batchId}_completed");
    $results = cache()->get("batch_invitations_{$batchId}_results");

    if ($total === null) {
        return response()->json([
            'message' => 'Batch not found',
        ], 404);
    }

    return response()->json([
        'batch_id' => $batchId,
        'total' => $total,
        'completed' => $completed,
        'results' => $completed ? $results : null,
    ]);
}
```

Finally, let's create a Livewire component for the batch invitation form:

```php
<?php

namespace App\Http\Livewire\Teams;

use App\Models\Team;
use Illuminate\Foundation\Auth\Access\AuthorizesRequests;
use Livewire\Component;

class BatchInviteMembers extends Component
{
    use AuthorizesRequests;

    public Team $team;
    public string $emails = '';
    public string $role = 'member';
    public ?string $batchId = null;
    public bool $processing = false;
    public array $results = [];

    protected $rules = [
        'emails' => 'required|string',
        'role' => 'required|string',
    ];

    public function invite()
    {
        $this->authorize('create', [TeamInvitation::class, $this->team]);

        $this->validate();

        $response = app(TeamInvitationController::class)->batchStore(
            request: new BatchTeamInvitationRequest([
                'emails' => $this->emails,
                'role' => $this->role,
            ]),
            team: $this->team
        );

        $data = json_decode($response->getContent(), true);
        $this->batchId = $data['batch_id'];
        $this->processing = true;

        // Start polling for status
        $this->dispatchBrowserEvent('batch-invitation-started', [
            'batchId' => $this->batchId,
        ]);
    }

    public function checkStatus()
    {
        if (!$this->batchId) {
            return;
        }

        $response = app(TeamInvitationController::class)->batchStatus(
            request: request(),
            batchId: $this->batchId
        );

        $data = json_decode($response->getContent(), true);

        if ($data['completed']) {
            $this->processing = false;
            $this->results = $data['results'];
            $this->dispatchBrowserEvent('batch-invitation-completed');
        }
    }

    public function resetForm()
    {
        $this->reset(['emails', 'batchId', 'processing', 'results']);
    }

    public function render()
    {
        return view('livewire.teams.batch-invite-members');
    }
}
```

And the view for the component:

```blade
<div>
    <div class="bg-white rounded-lg shadow p-6">
        <h3 class="text-lg font-medium text-gray-900">Batch Invite Team Members</h3>
        
        @if($processing)
            <div class="mt-4">
                <p class="text-sm text-gray-500">Processing invitations... This may take a moment.</p>
                <div class="mt-2 w-full bg-gray-200 rounded-full h-2.5">
                    <div class="bg-blue-600 h-2.5 rounded-full animate-pulse"></div>
                </div>
            </div>
        @elseif(!empty($results))
            <div class="mt-4">
                <h4 class="font-medium text-gray-700">Invitation Results</h4>
                
                @if(!empty($results['success']))
                    <div class="mt-2">
                        <h5 class="text-sm font-medium text-green-700">Successful Invitations ({{ count($results['success']) }})</h5>
                        <ul class="mt-1 text-sm text-gray-600 list-disc list-inside">
                            @foreach($results['success'] as $email => $message)
                                <li>{{ $email }}: {{ $message }}</li>
                            @endforeach
                        </ul>
                    </div>
                @endif
                
                @if(!empty($results['error']))
                    <div class="mt-2">
                        <h5 class="text-sm font-medium text-red-700">Failed Invitations ({{ count($results['error']) }})</h5>
                        <ul class="mt-1 text-sm text-gray-600 list-disc list-inside">
                            @foreach($results['error'] as $email => $message)
                                <li>{{ $email }}: {{ $message }}</li>
                            @endforeach
                        </ul>
                    </div>
                @endif
                
                <button wire:click="resetForm" class="mt-4 inline-flex items-center px-4 py-2 bg-gray-200 border border-transparent rounded-md font-semibold text-xs text-gray-700 uppercase tracking-widest hover:bg-gray-300 focus:bg-gray-300 active:bg-gray-400 focus:outline-none focus:ring-2 focus:ring-gray-500 focus:ring-offset-2 transition ease-in-out duration-150">
                    Send More Invitations
                </button>
            </div>
        @else
            <form wire:submit.prevent="invite" class="mt-4">
                <div>
                    <label for="emails" class="block text-sm font-medium text-gray-700">Email Addresses</label>
                    <p class="text-xs text-gray-500">Enter multiple email addresses separated by commas or new lines</p>
                    <textarea id="emails" wire:model.defer="emails" rows="5" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"></textarea>
                    @error('emails') <span class="text-red-500 text-xs">{{ $message }}</span> @enderror
                </div>

                <div class="mt-4">
                    <label for="role" class="block text-sm font-medium text-gray-700">Role</label>
                    <select id="role" wire:model.defer="role" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm">
                        <option value="member">Member</option>
                        <option value="admin">Admin</option>
                    </select>
                    @error('role') <span class="text-red-500 text-xs">{{ $message }}</span> @enderror
                </div>

                <div class="mt-6">
                    <button type="submit" class="inline-flex items-center px-4 py-2 bg-indigo-600 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-indigo-700 focus:bg-indigo-700 active:bg-indigo-900 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 transition ease-in-out duration-150">
                        Send Batch Invitations
                    </button>
                </div>
            </form>
        @endif
    </div>
    
    @if($batchId)
        <script>
            document.addEventListener('batch-invitation-started', function (event) {
                const checkStatus = setInterval(function() {
                    @this.checkStatus();
                }, 2000);
                
                document.addEventListener('batch-invitation-completed', function() {
                    clearInterval(checkStatus);
                });
            });
        </script>
    @endif
</div>
```
