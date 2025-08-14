### Practical Exercise Solution

Here's a sample implementation of a responsive team members list:

```php
<!-- resources/views/components/responsive-team-members.blade.php -->
<div class="space-y-4">
    <h2 class="text-lg font-medium">Team Members</h2>
    
    <!-- Responsive grid of team member cards -->
    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
        @foreach ($teamMembers as $member)
            <div class="bg-white rounded-lg shadow p-4">
                <div class="flex items-center space-x-4">
                    <img src="{{ $member->profile_photo_url }}" alt="{{ $member->name }}" class="h-12 w-12 rounded-full">
                    <div>
                        <h3 class="text-sm font-medium">{{ $member->name }}</h3>
                        <p class="text-xs text-gray-500">{{ $member->email }}</p>
                    </div>
                </div>
                <div class="mt-4 pt-4 border-t flex justify-between">
                    <span class="text-xs text-gray-500">{{ $member->role }}</span>
                    <div class="flex space-x-2">
                        <button class="text-blue-600 hover:text-blue-800">
                            <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path>
                            </svg>
                        </button>
                        <button class="text-red-600 hover:text-red-800">
                            <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
                            </svg>
                        </button>
                    </div>
                </div>
            </div>
        @endforeach
    </div>
</div>
```

This team members list implements the Column Drop pattern:

1. It shows as a single column on mobile (default)
2. Changes to 2 columns on small screens (`sm:grid-cols-2`)
3. Changes to 3 columns on large screens (`lg:grid-cols-3`)
4. Changes to 4 columns on extra large screens (`xl:grid-cols-4`)
5. Uses appropriate spacing and typography for each screen size

## Exercise 3: Touch Interactions

### Multiple Choice Answers

1. What is the recommended minimum size for touch targets?
   - **C) 44×44 pixels**

2. Which of the following is the best alternative to hover states on touch devices?
   - **C) Explicit toggle buttons**

3. When implementing swipe actions, what should you consider?
   - **B) Swipe gestures should have visual indicators**
