<div>
    <div class="grid gap-2">
        <label class="block text-sm font-medium text-gray-700">
            Profile Picture (optional)
        </label>
<<<<<<< HEAD

        <div class="flex space-x-4 mb-4">
            <button
                type="button"
=======
        
        <div class="flex space-x-4 mb-4">
            <button 
                type="button" 
>>>>>>> origin/develop
                class="px-3 py-1 text-xs font-medium rounded-md {{ $uploadType === 'file' ? 'bg-primary text-white' : 'bg-gray-200 text-gray-700' }}"
                wire:click="$set('uploadType', 'file')"
            >
                Upload File
            </button>
<<<<<<< HEAD
            <button
                type="button"
=======
            <button 
                type="button" 
>>>>>>> origin/develop
                class="px-3 py-1 text-xs font-medium rounded-md {{ $uploadType === 'url' ? 'bg-primary text-white' : 'bg-gray-200 text-gray-700' }}"
                wire:click="$set('uploadType', 'url')"
            >
                Use URL
            </button>
            @if($uploadType !== 'none')
<<<<<<< HEAD
                <button
                    type="button"
=======
                <button 
                    type="button" 
>>>>>>> origin/develop
                    class="px-3 py-1 text-xs font-medium rounded-md bg-red-100 text-red-700"
                    wire:click="removeAvatar"
                >
                    Remove
                </button>
            @endif
        </div>
<<<<<<< HEAD

        @if($uploadType === 'file')
            <div
=======
        
        @if($uploadType === 'file')
            <div 
>>>>>>> origin/develop
                x-data="{ isUploading: false, progress: 0 }"
                x-on:livewire-upload-start="isUploading = true"
                x-on:livewire-upload-finish="isUploading = false"
                x-on:livewire-upload-error="isUploading = false"
                x-on:livewire-upload-progress="progress = $event.detail.progress"
            >
                <div class="mt-1 flex justify-center px-6 pt-5 pb-6 border-2 border-gray-300 border-dashed rounded-md">
                    <div class="space-y-1 text-center">
                        <svg class="mx-auto h-12 w-12 text-gray-400" stroke="currentColor" fill="none" viewBox="0 0 48 48" aria-hidden="true">
                            <path d="M28 8H12a4 4 0 00-4 4v20m32-12v8m0 0v8a4 4 0 01-4 4H12a4 4 0 01-4-4v-4m32-4l-3.172-3.172a4 4 0 00-5.656 0L28 28M8 32l9.172-9.172a4 4 0 015.656 0L28 28m0 0l4 4m4-24h8m-4-4v8m-12 4h.02" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />
                        </svg>
                        <div class="flex text-sm text-gray-600">
                            <label for="avatar-upload" class="relative cursor-pointer bg-white rounded-md font-medium text-primary hover:text-primary-dark focus-within:outline-none focus-within:ring-2 focus-within:ring-offset-2 focus-within:ring-primary">
                                <span>Upload a file</span>
                                <input id="avatar-upload" wire:model="avatar" type="file" class="sr-only">
                            </label>
                            <p class="pl-1">or drag and drop</p>
                        </div>
                        <p class="text-xs text-gray-500">
                            PNG, JPG, GIF up to 1MB
                        </p>
                    </div>
                </div>
<<<<<<< HEAD

=======
                
>>>>>>> origin/develop
                <!-- Progress Bar -->
                <div x-show="isUploading" class="mt-2">
                    <div class="h-2 bg-gray-200 rounded-full">
                        <div class="h-2 bg-primary rounded-full" :style="`width: ${progress}%`"></div>
                    </div>
                </div>
<<<<<<< HEAD

                @error('avatar') <span class="text-red-500 text-sm">{{ $message }}</span> @enderror

=======
                
                @error('avatar') <span class="text-red-500 text-sm">{{ $message }}</span> @enderror
                
>>>>>>> origin/develop
                @if($avatar)
                    <div class="mt-4 flex items-center">
                        <img src="{{ $avatar->temporaryUrl() }}" alt="Avatar preview" class="h-16 w-16 rounded-full object-cover">
                        <p class="ml-4 text-sm text-gray-500">Your avatar will be uploaded when you complete registration</p>
                    </div>
                @endif
            </div>
        @elseif($uploadType === 'url')
            <div>
                <div class="mt-1">
<<<<<<< HEAD
                    <input
                        type="text"
                        wire:model.debounce.500ms="avatarUrl"
=======
                    <input 
                        type="text" 
                        wire:model.debounce.500ms="avatarUrl" 
>>>>>>> origin/develop
                        class="shadow-sm focus:ring-primary focus:border-primary block w-full sm:text-sm border-gray-300 rounded-md"
                        placeholder="https://example.com/avatar.jpg"
                    >
                </div>
                @error('avatarUrl') <span class="text-red-500 text-sm">{{ $message }}</span> @enderror
<<<<<<< HEAD

                @if($avatarUrl)
                    <div class="mt-4 flex items-center">
                        <img
                            src="{{ $avatarUrl }}"
                            alt="Avatar preview"
=======
                
                @if($avatarUrl)
                    <div class="mt-4 flex items-center">
                        <img 
                            src="{{ $avatarUrl }}" 
                            alt="Avatar preview" 
>>>>>>> origin/develop
                            class="h-16 w-16 rounded-full object-cover"
                            onerror="this.src='https://ui-avatars.com/api/?name=Preview&size=256&background=random'; this.onerror=null;"
                        >
                        <p class="ml-4 text-sm text-gray-500">Your avatar URL will be saved when you complete registration</p>
                    </div>
                @endif
            </div>
        @endif
<<<<<<< HEAD

=======
        
>>>>>>> origin/develop
        <input type="hidden" name="avatar_data" value="{{ json_encode($this->avatarData) }}">
    </div>
</div>
