### Practical Exercise Solution

Here's a sample implementation of a touch-friendly team member card component:

```php
<!-- resources/views/components/touch-friendly-team-member-card.blade.php -->
<div x-data="{ 
        swiped: false,
        touchStartX: 0,
        touchEndX: 0,
        
        handleTouchStart(e) {
            this.touchStartX = e.changedTouches[0].screenX;
        },
        
        handleTouchMove(e) {
            this.touchEndX = e.changedTouches[0].screenX;
            const diffX = this.touchStartX - this.touchEndX;
            
            if (diffX > 0) {
                // Swiping left
                const translateX = Math.min(diffX, 150);
                this.$refs.cardContent.style.transform = `translateX(-${translateX}px)`;
            } else {
                // Swiping right (to close)
                if (this.swiped) {
                    const translateX = Math.max(150 + diffX, 0);
                    this.$refs.cardContent.style.transform = `translateX(-${translateX}px)`;
                }
            }
        },
        
        handleTouchEnd(e) {
            const diffX = this.touchStartX - this.touchEndX;
            
            if (diffX > 100) {
                // Swiped left far enough to reveal actions
                this.swiped = true;
                this.$refs.cardContent.style.transform = 'translateX(-150px)';
            } else if (diffX < -50 && this.swiped) {
                // Swiped right far enough to hide actions
                this.swiped = false;
                this.$refs.cardContent.style.transform = 'translateX(0)';
            } else {
                // Not swiped far enough, return to original position
                this.$refs.cardContent.style.transform = this.swiped ? 'translateX(-150px)' : 'translateX(0)';
            }
        },
        
        resetSwipe() {
            this.swiped = false;
            this.$refs.cardContent.style.transform = 'translateX(0)';
        }
     }"
     class="relative overflow-hidden bg-white rounded-lg shadow mb-4">
    
    <!-- Visual indicator for swipe gesture (visible on touch devices) -->
    <div class="absolute inset-y-0 right-4 flex items-center pointer-events-none md:hidden">
        <svg class="h-6 w-6 text-gray-400 animate-pulse" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"></path>
        </svg>
    </div>
    
    <!-- Card content -->
    <div x-ref="cardContent"
         @touchstart="handleTouchStart"
         @touchmove="handleTouchMove"
         @touchend="handleTouchEnd"
         class="relative bg-white z-10 transition-transform duration-200 ease-out">
        <div class="p-4">
            <div class="flex items-center space-x-4">
                <img src="{{ $member->profile_photo_url }}" alt="{{ $member->name }}" class="h-12 w-12 rounded-full">
                <div>
                    <h3 class="text-sm font-medium">{{ $member->name }}</h3>
                    <p class="text-xs text-gray-500">{{ $member->email }}</p>
                </div>
            </div>
            <div class="mt-4 pt-4 border-t">
                <span class="text-xs text-gray-500">{{ $member->role }}</span>
            </div>
            
            <!-- Desktop actions (visible on hover) -->
            <div class="hidden md:flex md:absolute md:top-4 md:right-4 md:opacity-0 md:group-hover:opacity-100 md:transition-opacity md:duration-200 md:space-x-2">
                <button class="p-2 text-blue-600 hover:text-blue-800 rounded-full hover:bg-blue-50 min-h-[44px] min-w-[44px] flex items-center justify-center">
                    <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path>
                    </svg>
                </button>
                <button class="p-2 text-red-600 hover:text-red-800 rounded-full hover:bg-red-50 min-h-[44px] min-w-[44px] flex items-center justify-center">
                    <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
                    </svg>
                </button>
            </div>
        </div>
    </div>
    
    <!-- Swipe actions (revealed on swipe) -->
    <div class="absolute inset-y-0 right-0 flex h-full">
        <button @click="$dispatch('edit-member', { id: {{ $member->id }} }); resetSwipe()" 
                class="bg-blue-500 text-white flex items-center justify-center w-[75px] min-h-[44px]">
            <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path>
            </svg>
        </button>
        <button @click="$dispatch('delete-member', { id: {{ $member->id }} }); resetSwipe()" 
                class="bg-red-500 text-white flex items-center justify-center w-[75px] min-h-[44px]">
            <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
            </svg>
        </button>
    </div>
    
    <!-- Fallback for non-touch devices (button to show actions) -->
    <button @click="swiped = !swiped; $refs.cardContent.style.transform = swiped ? 'translateX(-150px)' : 'translateX(0)'" 
            class="absolute top-4 right-4 md:hidden p-2 rounded-full bg-gray-100 min-h-[44px] min-w-[44px] flex items-center justify-center">
        <svg class="h-5 w-5 text-gray-500" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 12h.01M12 12h.01M19 12h.01M6 12a1 1 0 11-2 0 1 1 0 012 0zm7 0a1 1 0 11-2 0 1 1 0 012 0zm7 0a1 1 0 11-2 0 1 1 0 012 0z"></path>
        </svg>
    </button>
</div>
```

This team member card component is touch-friendly:

1. It has adequately sized touch targets (min-height and min-width of 44px)
2. It implements swipe-to-reveal actions (edit and delete)
3. It provides visual feedback for touch interactions with transitions
4. It includes a fallback button for devices that don't support touch events
5. It has different interaction patterns for touch devices (swipe) and desktop (hover)

## Exercise 4: Performance Optimization

### Multiple Choice Answers

1. Which of the following has the biggest impact on mobile performance?
   - **A) JavaScript execution**

2. What is the best approach for handling images on mobile devices?
   - **B) Use responsive images with appropriate sizes for different devices**

3. Which of the following is NOT a valid strategy for optimizing JavaScript on mobile?
   - **C) Using more animations**
