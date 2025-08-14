### Practical Exercise Solution

Here's a sample implementation of performance optimizations for a UME application:

#### 1. Lazy Loading for Team Member Avatars

```php
<!-- resources/views/components/lazy-avatar.blade.php -->
<div class="avatar-container" style="width: {{ $size }}px; height: {{ $size }}px;">
    <img 
        src="{{ asset('images/placeholder-avatar.svg') }}" 
        data-src="{{ $user->getFirstMediaUrl('avatars', $conversion) }}" 
        alt="{{ $user->name }}" 
        class="lazy-avatar rounded-full w-full h-full object-cover"
        loading="lazy"
    >
</div>

<!-- JavaScript for lazy loading (resources/js/lazy-loading.js) -->
<script>
document.addEventListener('DOMContentLoaded', function() {
    // Check if IntersectionObserver is supported
    if ('IntersectionObserver' in window) {
        const lazyAvatars = document.querySelectorAll('.lazy-avatar');
        
        const avatarObserver = new IntersectionObserver(function(entries, observer) {
            entries.forEach(function(entry) {
                if (entry.isIntersecting) {
                    const avatar = entry.target;
                    avatar.src = avatar.dataset.src;
                    avatar.classList.remove('lazy-avatar');
                    avatarObserver.unobserve(avatar);
                }
            });
        });
        
        lazyAvatars.forEach(function(avatar) {
            avatarObserver.observe(avatar);
        });
    } else {
        // Fallback for browsers that don't support IntersectionObserver
        const lazyAvatars = document.querySelectorAll('.lazy-avatar');
        
        lazyAvatars.forEach(function(avatar) {
            avatar.src = avatar.dataset.src;
            avatar.classList.remove('lazy-avatar');
        });
    }
});
</script>
```

#### 2. Optimized API Responses for Mobile

```php
// app/Http/Controllers/API/TeamMembersController.php
public function index(Request $request)
{
    $isMobile = $request->header('X-Device-Type') === 'mobile' || 
                (strpos($request->userAgent(), 'Mobile') !== false);
    
    $query = TeamMember::query();
    
    // Apply filters
    if ($request->has('team_id')) {
        $query->where('team_id', $request->team_id);
    }
    
    // Get team members with optimized data for mobile
    $teamMembers = $query->get();
    
    // Transform the data based on device type
    $transformedMembers = $teamMembers->map(function ($member) use ($isMobile) {
        $data = [
            'id' => $member->id,
            'name' => $member->name,
            'role' => $member->role,
        ];
        
        // Include avatar URL optimized for device
        if ($member->hasMedia('avatars')) {
            $data['avatar'] = $member->getFirstMediaUrl('avatars', $isMobile ? 'thumb' : 'medium');
        } else {
            $data['avatar'] = null;
        }
        
        // Include additional data for desktop only
        if (!$isMobile) {
            $data['email'] = $member->email;
            $data['phone'] = $member->phone;
            $data['created_at'] = $member->created_at;
            $data['permissions'] = $member->permissions;
        }
        
        return $data;
    });
    
    return response()->json([
        'team_members' => $transformedMembers,
    ]);
}
```

#### 3. Efficient Event Handling for Touch Interactions

```javascript
// resources/js/efficient-touch-handling.js
class TouchHandler {
    constructor(element, options = {}) {
        this.element = element;
        this.options = Object.assign({
            threshold: 50,
            preventScroll: false,
            debounceTime: 100
        }, options);
        
        this.touchStartX = 0;
        this.touchStartY = 0;
        this.touchEndX = 0;
        this.touchEndY = 0;
        this.isScrolling = false;
        this.touchTimeout = null;
        
        this.onTouchStart = this.onTouchStart.bind(this);
        this.onTouchMove = this.onTouchMove.bind(this);
        this.onTouchEnd = this.onTouchEnd.bind(this);
        
        this.init();
    }
    
    init() {
        // Use passive listeners where appropriate for better performance
        this.element.addEventListener('touchstart', this.onTouchStart, { passive: !this.options.preventScroll });
        this.element.addEventListener('touchmove', this.onTouchMove, { passive: !this.options.preventScroll });
        this.element.addEventListener('touchend', this.onTouchEnd, { passive: true });
    }
    
    onTouchStart(event) {
        // Store initial touch position
        this.touchStartX = event.touches[0].clientX;
        this.touchStartY = event.touches[0].clientY;
        this.isScrolling = false;
        
        // Prevent default if needed
        if (this.options.preventScroll) {
            event.preventDefault();
        }
        
        // Dispatch custom event
        this.element.dispatchEvent(new CustomEvent('swipe-start', {
            detail: {
                x: this.touchStartX,
                y: this.touchStartY
            }
        }));
    }
    
    onTouchMove(event) {
        // Debounce touch move events for better performance
        if (this.touchTimeout) {
            clearTimeout(this.touchTimeout);
        }
        
        this.touchTimeout = setTimeout(() => {
            // Update current touch position
            this.touchEndX = event.touches[0].clientX;
            this.touchEndY = event.touches[0].clientY;
            
            // Determine if user is scrolling vertically
            if (!this.isScrolling) {
                this.isScrolling = Math.abs(this.touchEndY - this.touchStartY) > Math.abs(this.touchEndX - this.touchStartX);
            }
            
            // If scrolling vertically, don't handle as swipe
            if (this.isScrolling) return;
            
            // Prevent default if needed
            if (this.options.preventScroll) {
                event.preventDefault();
            }
            
            // Calculate swipe distance
            const diffX = this.touchStartX - this.touchEndX;
            
            // Dispatch custom event
            this.element.dispatchEvent(new CustomEvent('swipe-move', {
                detail: {
                    diffX: diffX,
                    diffY: this.touchStartY - this.touchEndY,
                    isScrolling: this.isScrolling
                }
            }));
        }, this.options.debounceTime);
    }
    
    onTouchEnd(event) {
        // Clear any pending timeout
        if (this.touchTimeout) {
            clearTimeout(this.touchTimeout);
        }
        
        // If scrolling vertically, don't handle as swipe
        if (this.isScrolling) return;
        
        // Calculate final swipe distance
        const diffX = this.touchStartX - this.touchEndX;
        
        // Determine swipe direction if it exceeds threshold
        let swipeDirection = null;
        if (Math.abs(diffX) > this.options.threshold) {
            swipeDirection = diffX > 0 ? 'left' : 'right';
        }
        
        // Dispatch custom event
        this.element.dispatchEvent(new CustomEvent('swipe-end', {
            detail: {
                direction: swipeDirection,
                diffX: diffX,
                diffY: this.touchStartY - this.touchEndY
            }
        }));
    }
    
    destroy() {
        this.element.removeEventListener('touchstart', this.onTouchStart);
        this.element.removeEventListener('touchmove', this.onTouchMove);
        this.element.removeEventListener('touchend', this.onTouchEnd);
    }
}

// Usage
document.querySelectorAll('.swipeable-card').forEach(card => {
    const touchHandler = new TouchHandler(card, {
        threshold: 50,
        debounceTime: 10
    });
    
    card.addEventListener('swipe-end', event => {
        if (event.detail.direction === 'left') {
            // Handle left swipe
            card.classList.add('swiped-left');
        } else if (event.detail.direction === 'right') {
            // Handle right swipe
            card.classList.remove('swiped-left');
        }
    });
});
```

#### 4. Performance Testing with Chrome DevTools

To test the performance of these optimizations:

1. Open Chrome DevTools (F12)
2. Go to the Performance tab
3. Click the record button
4. Interact with the page (scroll, swipe, etc.)
5. Stop recording
6. Analyze the results, looking for:
   - Long tasks (shown in red)
   - Layout shifts
   - JavaScript execution time
   - Rendering performance

Based on the performance analysis, further optimizations might include:

- Reducing JavaScript bundle size through code splitting
- Minimizing main thread work by using Web Workers
- Optimizing CSS selectors and reducing specificity
- Implementing virtualized lists for long team member lists
- Using CSS containment to isolate parts of the page

## Exercise 5: Offline Capabilities

### Multiple Choice Answers

1. Which API is fundamental for implementing offline capabilities?
   - **C) Service Worker API**

2. What is the best approach for handling form submissions when offline?
   - **C) Store the submission and sync when online**

3. Which of the following is NOT typically cached for offline use?
   - **D) User-specific data**
