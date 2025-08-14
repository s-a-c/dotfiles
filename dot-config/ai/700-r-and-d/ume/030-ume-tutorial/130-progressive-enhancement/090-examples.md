# UME Examples

<link rel="stylesheet" href="../assets/css/styles.css">

This page provides practical examples of progressive enhancement applied to UME features. These examples demonstrate how to implement core functionality that works for all users, then enhance it for browsers with more advanced capabilities.

## User Profile Management

### Basic Implementation

Start with a server-rendered form that works without JavaScript:

```html
<!-- resources/views/user/profile/edit.blade.php -->
<form action="{{ route('user.profile.update') }}" method="POST" enctype="multipart/form-data">
    @csrf
    @method('PUT')
    
    <div class="form-group">
        <label for="name">Name</label>
        <input type="text" id="name" name="name" value="{{ old('name', $user->name) }}" required>
        @error('name')
            <span class="error">{{ $message }}</span>
        @enderror
    </div>
    
    <div class="form-group">
        <label for="email">Email</label>
        <input type="email" id="email" name="email" value="{{ old('email', $user->email) }}" required>
        @error('email')
            <span class="error">{{ $message }}</span>
        @enderror
    </div>
    
    <div class="form-group">
        <label for="bio">Bio</label>
        <textarea id="bio" name="bio" rows="4">{{ old('bio', $user->bio) }}</textarea>
        @error('bio')
            <span class="error">{{ $message }}</span>
        @enderror
    </div>
    
    <div class="form-group">
        <label for="avatar">Profile Picture</label>
        <input type="file" id="avatar" name="avatar" accept="image/*">
        @error('avatar')
            <span class="error">{{ $message }}</span>
        @enderror
    </div>
    
    <button type="submit">Update Profile</button>
</form>
```

```php
// app/Http/Controllers/UserProfileController.php
public function update(Request $request)
{
    $validated = $request->validate([
        'name' => 'required|string|max:255',
        'email' => 'required|email|unique:users,email,' . auth()->id(),
        'bio' => 'nullable|string|max:1000',
        'avatar' => 'nullable|image|max:1024',
    ]);
    
    $user = auth()->user();
    
    // Update basic fields
    $user->name = $validated['name'];
    $user->email = $validated['email'];
    $user->bio = $validated['bio'];
    
    // Handle avatar upload
    if ($request->hasFile('avatar')) {
        $path = $request->file('avatar')->store('avatars', 'public');
        $user->avatar = $path;
    }
    
    $user->save();
    
    return redirect()->route('user.profile.show')
        ->with('success', 'Profile updated successfully');
}
```

### Progressive Enhancement

Enhance the form with JavaScript for a better user experience:

```html
<!-- resources/views/user/profile/edit.blade.php with enhancements -->
<form id="profile-form" action="{{ route('user.profile.update') }}" method="POST" enctype="multipart/form-data">
    @csrf
    @method('PUT')
    
    <div class="form-group">
        <label for="name">Name</label>
        <input type="text" id="name" name="name" value="{{ old('name', $user->name) }}" required>
        <span class="error-message" id="name-error"></span>
        @error('name')
            <span class="error">{{ $message }}</span>
        @enderror
    </div>
    
    <div class="form-group">
        <label for="email">Email</label>
        <input type="email" id="email" name="email" value="{{ old('email', $user->email) }}" required>
        <span class="error-message" id="email-error"></span>
        @error('email')
            <span class="error">{{ $message }}</span>
        @enderror
    </div>
    
    <div class="form-group">
        <label for="bio">Bio</label>
        <textarea id="bio" name="bio" rows="4">{{ old('bio', $user->bio) }}</textarea>
        <span class="character-count">0/1000 characters</span>
        @error('bio')
            <span class="error">{{ $message }}</span>
        @enderror
    </div>
    
    <div class="form-group">
        <label for="avatar">Profile Picture</label>
        <div class="avatar-upload">
            <div class="avatar-preview">
                <img src="{{ $user->avatar_url }}" alt="Profile picture" id="avatar-preview-image">
            </div>
            <input type="file" id="avatar" name="avatar" accept="image/*">
        </div>
        @error('avatar')
            <span class="error">{{ $message }}</span>
        @enderror
    </div>
    
    <button type="submit" id="submit-button">Update Profile</button>
</form>

<script>
document.addEventListener('DOMContentLoaded', function() {
    // Only apply enhancements if JavaScript is available
    const form = document.getElementById('profile-form');
    
    if (!form) return;
    
    // Feature detection
    const hasFormValidation = 'reportValidity' in form;
    const hasFileReader = 'FileReader' in window;
    const hasFetch = 'fetch' in window;
    
    // Enhancement: Real-time character count
    const bioField = document.getElementById('bio');
    const charCount = document.querySelector('.character-count');
    
    if (bioField && charCount) {
        function updateCharCount() {
            const count = bioField.value.length;
            charCount.textContent = `${count}/1000 characters`;
            
            // Visual feedback
            if (count > 900) {
                charCount.classList.add('near-limit');
            } else {
                charCount.classList.remove('near-limit');
            }
        }
        
        bioField.addEventListener('input', updateCharCount);
        updateCharCount(); // Initial count
    }
    
    // Enhancement: Image preview
    const avatarInput = document.getElementById('avatar');
    const previewImage = document.getElementById('avatar-preview-image');
    
    if (avatarInput && previewImage && hasFileReader) {
        avatarInput.addEventListener('change', function() {
            if (this.files && this.files[0]) {
                const reader = new FileReader();
                
                reader.onload = function(e) {
                    previewImage.src = e.target.result;
                }
                
                reader.readAsDataURL(this.files[0]);
            }
        });
    }
    
    // Enhancement: Client-side validation
    if (hasFormValidation) {
        const nameInput = document.getElementById('name');
        const emailInput = document.getElementById('email');
        const nameError = document.getElementById('name-error');
        const emailError = document.getElementById('email-error');
        
        nameInput.addEventListener('blur', function() {
            if (this.validity.valueMissing) {
                nameError.textContent = 'Name is required';
            } else if (this.value.length > 255) {
                nameError.textContent = 'Name must be less than 255 characters';
            } else {
                nameError.textContent = '';
            }
        });
        
        emailInput.addEventListener('blur', function() {
            if (this.validity.valueMissing) {
                emailError.textContent = 'Email is required';
            } else if (this.validity.typeMismatch) {
                emailError.textContent = 'Please enter a valid email address';
            } else {
                emailError.textContent = '';
            }
        });
    }
    
    // Enhancement: AJAX form submission
    if (hasFetch) {
        form.addEventListener('submit', async function(e) {
            e.preventDefault();
            
            // Show loading state
            const submitButton = document.getElementById('submit-button');
            const originalButtonText = submitButton.textContent;
            submitButton.textContent = 'Updating...';
            submitButton.disabled = true;
            
            try {
                const formData = new FormData(form);
                
                const response = await fetch(form.action, {
                    method: 'POST',
                    body: formData,
                    headers: {
                        'X-Requested-With': 'XMLHttpRequest',
                        'Accept': 'application/json'
                    }
                });
                
                if (response.ok) {
                    const data = await response.json();
                    
                    // Show success message
                    const successMessage = document.createElement('div');
                    successMessage.className = 'alert alert-success';
                    successMessage.textContent = data.message || 'Profile updated successfully';
                    form.parentNode.insertBefore(successMessage, form);
                    
                    // Scroll to success message
                    successMessage.scrollIntoView({ behavior: 'smooth' });
                    
                    // Reset button
                    submitButton.textContent = originalButtonText;
                    submitButton.disabled = false;
                } else {
                    // Handle validation errors
                    const data = await response.json();
                    
                    if (data.errors) {
                        // Display validation errors
                        Object.keys(data.errors).forEach(field => {
                            const errorElement = document.getElementById(`${field}-error`);
                            if (errorElement) {
                                errorElement.textContent = data.errors[field][0];
                            }
                        });
                    }
                    
                    // Reset button
                    submitButton.textContent = originalButtonText;
                    submitButton.disabled = false;
                }
            } catch (error) {
                console.error('Error:', error);
                
                // If AJAX fails, fall back to traditional form submission
                submitButton.textContent = originalButtonText;
                submitButton.disabled = false;
                form.submit();
            }
        });
    }
});
</script>
```

```php
// app/Http/Controllers/UserProfileController.php with AJAX support
public function update(Request $request)
{
    $validated = $request->validate([
        'name' => 'required|string|max:255',
        'email' => 'required|email|unique:users,email,' . auth()->id(),
        'bio' => 'nullable|string|max:1000',
        'avatar' => 'nullable|image|max:1024',
    ]);
    
    $user = auth()->user();
    
    // Update basic fields
    $user->name = $validated['name'];
    $user->email = $validated['email'];
    $user->bio = $validated['bio'];
    
    // Handle avatar upload
    if ($request->hasFile('avatar')) {
        $path = $request->file('avatar')->store('avatars', 'public');
        $user->avatar = $path;
    }
    
    $user->save();
    
    // Return JSON response for AJAX requests
    if ($request->ajax()) {
        return response()->json([
            'success' => true,
            'message' => 'Profile updated successfully',
            'user' => $user
        ]);
    }
    
    // Return redirect for traditional form submissions
    return redirect()->route('user.profile.show')
        ->with('success', 'Profile updated successfully');
}
```

## Team Management

### Basic Implementation

Start with a server-rendered team management interface:

```html
<!-- resources/views/teams/index.blade.php -->
<div class="teams-container">
    <h1>Your Teams</h1>
    
    @if(session('success'))
        <div class="alert alert-success">
            {{ session('success') }}
        </div>
    @endif
    
    <div class="teams-actions">
        <a href="{{ route('teams.create') }}" class="button">Create New Team</a>
    </div>
    
    @if($teams->isEmpty())
        <p>You don't have any teams yet. Create your first team to get started.</p>
    @else
        <ul class="teams-list">
            @foreach($teams as $team)
                <li class="team-item">
                    <div class="team-info">
                        <h2>{{ $team->name }}</h2>
                        <p>{{ $team->members_count }} members</p>
                    </div>
                    <div class="team-actions">
                        <a href="{{ route('teams.show', $team) }}" class="button">View</a>
                        @if($team->user_can_manage)
                            <a href="{{ route('teams.edit', $team) }}" class="button">Edit</a>
                            <form action="{{ route('teams.destroy', $team) }}" method="POST" class="inline-form">
                                @csrf
                                @method('DELETE')
                                <button type="submit" class="button button-danger" 
                                        onclick="return confirm('Are you sure you want to delete this team?')">
                                    Delete
                                </button>
                            </form>
                        @endif
                    </div>
                </li>
            @endforeach
        </ul>
        
        {{ $teams->links() }}
    @endif
</div>
```

```php
// app/Http/Controllers/TeamController.php
public function index()
{
    $teams = auth()->user()->teams()->withCount('members')->paginate(10);
    
    // Add a flag to indicate if the user can manage each team
    $teams->each(function ($team) {
        $team->user_can_manage = auth()->user()->can('manage', $team);
    });
    
    return view('teams.index', compact('teams'));
}
```

### Progressive Enhancement

Enhance the team management interface with JavaScript:

```html
<!-- resources/views/teams/index.blade.php with enhancements -->
<div class="teams-container" id="teams-app">
    <h1>Your Teams</h1>
    
    @if(session('success'))
        <div class="alert alert-success">
            {{ session('success') }}
        </div>
    @endif
    
    <div class="teams-actions">
        <a href="{{ route('teams.create') }}" class="button">Create New Team</a>
        
        <!-- Enhanced search (only appears with JS) -->
        <div class="search-container" style="display: none;">
            <input type="text" id="team-search" placeholder="Search teams..." aria-label="Search teams">
        </div>
    </div>
    
    @if($teams->isEmpty())
        <p>You don't have any teams yet. Create your first team to get started.</p>
    @else
        <div class="view-options" style="display: none;">
            <button type="button" class="view-option" data-view="list" aria-pressed="true">List View</button>
            <button type="button" class="view-option" data-view="grid" aria-pressed="false">Grid View</button>
        </div>
        
        <ul class="teams-list" id="teams-list">
            @foreach($teams as $team)
                <li class="team-item" data-team-id="{{ $team->id }}" data-team-name="{{ $team->name }}">
                    <div class="team-info">
                        <h2>{{ $team->name }}</h2>
                        <p>{{ $team->members_count }} members</p>
                    </div>
                    <div class="team-actions">
                        <a href="{{ route('teams.show', $team) }}" class="button">View</a>
                        @if($team->user_can_manage)
                            <a href="{{ route('teams.edit', $team) }}" class="button">Edit</a>
                            <form action="{{ route('teams.destroy', $team) }}" method="POST" class="inline-form delete-team-form">
                                @csrf
                                @method('DELETE')
                                <button type="submit" class="button button-danger delete-team-button">
                                    Delete
                                </button>
                            </form>
                        @endif
                    </div>
                </li>
            @endforeach
        </ul>
        
        {{ $teams->links() }}
    @endif
    
    <!-- Enhanced confirmation modal (only appears with JS) -->
    <div id="confirmation-modal" class="modal" style="display: none;" aria-hidden="true" role="dialog" aria-labelledby="modal-title">
        <div class="modal-content">
            <h2 id="modal-title">Confirm Deletion</h2>
            <p>Are you sure you want to delete this team? This action cannot be undone.</p>
            <div class="modal-actions">
                <button type="button" class="button" id="cancel-delete">Cancel</button>
                <button type="button" class="button button-danger" id="confirm-delete">Delete</button>
            </div>
        </div>
    </div>
</div>

<script>
document.addEventListener('DOMContentLoaded', function() {
    // Only apply enhancements if JavaScript is available
    const teamsContainer = document.getElementById('teams-app');
    const teamsList = document.getElementById('teams-list');
    
    if (!teamsContainer || !teamsList) return;
    
    // Feature detection
    const hasLocalStorage = (function() {
        try {
            localStorage.setItem('test', 'test');
            localStorage.removeItem('test');
            return true;
        } catch (e) {
            return false;
        }
    })();
    
    const hasFetch = 'fetch' in window;
    
    // Enhancement: Search functionality
    const searchContainer = document.querySelector('.search-container');
    if (searchContainer) {
        // Show search box
        searchContainer.style.display = 'block';
        
        const searchInput = document.getElementById('team-search');
        if (searchInput) {
            searchInput.addEventListener('input', function() {
                const searchTerm = this.value.toLowerCase();
                const teamItems = teamsList.querySelectorAll('.team-item');
                
                teamItems.forEach(item => {
                    const teamName = item.getAttribute('data-team-name').toLowerCase();
                    const isVisible = teamName.includes(searchTerm);
                    item.style.display = isVisible ? '' : 'none';
                });
                
                // Show message if no results
                let visibleCount = 0;
                teamItems.forEach(item => {
                    if (item.style.display !== 'none') {
                        visibleCount++;
                    }
                });
                
                // Remove existing "no results" message
                const existingMessage = teamsContainer.querySelector('.no-results-message');
                if (existingMessage) {
                    existingMessage.remove();
                }
                
                // Add "no results" message if needed
                if (visibleCount === 0 && searchTerm !== '') {
                    const noResultsMessage = document.createElement('p');
                    noResultsMessage.className = 'no-results-message';
                    noResultsMessage.textContent = `No teams found matching "${searchTerm}"`;
                    teamsList.parentNode.insertBefore(noResultsMessage, teamsList.nextSibling);
                }
            });
        }
    }
    
    // Enhancement: View options
    const viewOptions = document.querySelector('.view-options');
    if (viewOptions) {
        // Show view options
        viewOptions.style.display = 'flex';
        
        const viewButtons = viewOptions.querySelectorAll('.view-option');
        
        // Load saved view preference
        if (hasLocalStorage) {
            const savedView = localStorage.getItem('teams-view-preference');
            if (savedView) {
                teamsList.className = `teams-list ${savedView}-view`;
                
                // Update button states
                viewButtons.forEach(button => {
                    const isActive = button.getAttribute('data-view') === savedView;
                    button.setAttribute('aria-pressed', isActive);
                    if (isActive) {
                        button.classList.add('active');
                    } else {
                        button.classList.remove('active');
                    }
                });
            }
        }
        
        // Handle view switching
        viewButtons.forEach(button => {
            button.addEventListener('click', function() {
                const viewType = this.getAttribute('data-view');
                
                // Update list class
                teamsList.className = `teams-list ${viewType}-view`;
                
                // Update button states
                viewButtons.forEach(btn => {
                    const isActive = btn === this;
                    btn.setAttribute('aria-pressed', isActive);
                    if (isActive) {
                        btn.classList.add('active');
                    } else {
                        btn.classList.remove('active');
                    }
                });
                
                // Save preference
                if (hasLocalStorage) {
                    localStorage.setItem('teams-view-preference', viewType);
                }
            });
        });
    }
    
    // Enhancement: Confirmation modal for deletion
    const deleteButtons = document.querySelectorAll('.delete-team-button');
    const modal = document.getElementById('confirmation-modal');
    
    if (deleteButtons.length > 0 && modal) {
        let currentForm = null;
        
        // Replace default confirmation with modal
        deleteButtons.forEach(button => {
            button.onclick = function(e) {
                e.preventDefault();
                currentForm = this.closest('form');
                
                // Show modal
                modal.style.display = 'flex';
                modal.setAttribute('aria-hidden', 'false');
                
                // Focus first button in modal
                document.getElementById('cancel-delete').focus();
                
                // Trap focus in modal
                modal.addEventListener('keydown', trapFocus);
            };
        });
        
        // Handle modal actions
        document.getElementById('cancel-delete').addEventListener('click', function() {
            closeModal();
        });
        
        document.getElementById('confirm-delete').addEventListener('click', function() {
            if (currentForm) {
                if (hasFetch) {
                    // Submit form via AJAX
                    const formData = new FormData(currentForm);
                    const action = currentForm.getAttribute('action');
                    
                    fetch(action, {
                        method: 'POST',
                        body: formData,
                        headers: {
                            'X-Requested-With': 'XMLHttpRequest',
                            'Accept': 'application/json'
                        }
                    })
                    .then(response => response.json())
                    .then(data => {
                        if (data.success) {
                            // Remove team from list
                            const teamItem = currentForm.closest('.team-item');
                            teamItem.remove();
                            
                            // Show success message
                            const successMessage = document.createElement('div');
                            successMessage.className = 'alert alert-success';
                            successMessage.textContent = data.message || 'Team deleted successfully';
                            teamsContainer.insertBefore(successMessage, teamsContainer.firstChild);
                            
                            // Close modal
                            closeModal();
                        }
                    })
                    .catch(error => {
                        console.error('Error:', error);
                        // Fall back to traditional form submission
                        currentForm.submit();
                    });
                } else {
                    // Traditional form submission
                    currentForm.submit();
                }
            }
        });
        
        // Close modal when clicking outside
        modal.addEventListener('click', function(e) {
            if (e.target === modal) {
                closeModal();
            }
        });
        
        // Close modal with Escape key
        document.addEventListener('keydown', function(e) {
            if (e.key === 'Escape' && modal.style.display === 'flex') {
                closeModal();
            }
        });
        
        function closeModal() {
            modal.style.display = 'none';
            modal.setAttribute('aria-hidden', 'true');
            modal.removeEventListener('keydown', trapFocus);
            
            // Return focus to the delete button
            if (currentForm) {
                currentForm.querySelector('.delete-team-button').focus();
            }
        }
        
        function trapFocus(e) {
            if (e.key === 'Tab') {
                const focusableElements = modal.querySelectorAll('button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])');
                const firstElement = focusableElements[0];
                const lastElement = focusableElements[focusableElements.length - 1];
                
                if (e.shiftKey) {
                    if (document.activeElement === firstElement) {
                        lastElement.focus();
                        e.preventDefault();
                    }
                } else {
                    if (document.activeElement === lastElement) {
                        firstElement.focus();
                        e.preventDefault();
                    }
                }
            }
        }
    }
});
</script>
```

```php
// app/Http/Controllers/TeamController.php with AJAX support
public function destroy(Team $team)
{
    $this->authorize('manage', $team);
    
    $team->delete();
    
    // Return JSON response for AJAX requests
    if (request()->ajax()) {
        return response()->json([
            'success' => true,
            'message' => 'Team deleted successfully'
        ]);
    }
    
    // Return redirect for traditional form submissions
    return redirect()->route('teams.index')
        ->with('success', 'Team deleted successfully');
}
```

## Next Steps

Continue to [Decision Tree](./100-decision-tree.md) to learn how to make decisions about implementation approaches for progressive enhancement in your UME application.
