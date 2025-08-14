@props(['user', 'size' => 'md', 'showInitials' => true])

@php
    $sizeClasses = [
        'xs' => 'h-6 w-6 text-xs',
        'sm' => 'h-8 w-8 text-sm',
        'md' => 'h-10 w-10 text-base',
        'lg' => 'h-16 w-16 text-xl',
        'xl' => 'h-24 w-24 text-2xl',
    ][$size] ?? 'h-10 w-10 text-base';
@endphp

<div {{ $attributes->merge(['class' => "relative inline-block {$sizeClasses}"]) }}>
    @if ($user->avatar_url)
        <img 
            src="{{ $user->avatar_url }}" 
            alt="{{ $user->name }}" 
            class="rounded-full object-cover w-full h-full"
            onerror="this.onerror=null; this.src='https://ui-avatars.com/api/?name={{ urlencode($user->name) }}&size=256&background=random';"
        >
    @elseif ($showInitials)
        <div class="flex items-center justify-center w-full h-full rounded-full bg-primary/10 text-primary font-medium">
            {{ $user->getInitials() }}
        </div>
    @else
        <div class="flex items-center justify-center w-full h-full rounded-full bg-gray-200">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-1/2 w-1/2 text-gray-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
            </svg>
        </div>
    @endif
</div>
