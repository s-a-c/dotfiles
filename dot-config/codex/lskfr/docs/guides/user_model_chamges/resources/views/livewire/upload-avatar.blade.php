<div>
    <div class="flex items-center space-x-4">
        <div class="relative">
            @if(auth()->user()->avatar_url)
                <img src="{{ auth()->user()->avatar_url }}" alt="{{ auth()->user()->name }}" class="h-20 w-20 rounded-full object-cover">
            @else
                <div class="h-20 w-20 rounded-full bg-gray-200 flex items-center justify-center text-gray-500">
                    {{ auth()->user()->getInitials() }}
                </div>
            @endif
            
            <button 
                type="button" 
                wire:click="openModal" 
                class="absolute bottom-0 right-0 rounded-full bg-primary p-1 text-white shadow-sm"
                title="Change avatar"
            >
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" viewBox="0 0 20 20" fill="currentColor">
                    <path d="M13.586 3.586a2 2 0 112.828 2.828l-.793.793-2.828-2.828.793-.793zM11.379 5.793L3 14.172V17h2.828l8.38-8.379-2.83-2.828z" />
                </svg>
            </button>
        </div>
        
        <div>
            <h3 class="text-lg font-medium">{{ auth()->user()->name }}</h3>
            <p class="text-sm text-gray-500">{{ auth()->user()->email }}</p>
        </div>
    </div>
    
    <!-- Modal -->
    @if($showModal)
    <div class="fixed inset-0 z-50 overflow-y-auto" aria-labelledby="modal-title" role="dialog" aria-modal="true">
        <div class="flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
            <div class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity" aria-hidden="true" wire:click="closeModal"></div>

            <span class="hidden sm:inline-block sm:align-middle sm:h-screen" aria-hidden="true">&#8203;</span>

            <div class="inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full">
                <div class="bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
                    <div class="sm:flex sm:items-start">
                        <div class="mt-3 text-center sm:mt-0 sm:ml-4 sm:text-left w-full">
                            <h3 class="text-lg leading-6 font-medium text-gray-900" id="modal-title">
                                Update Avatar
                            </h3>
                            
                            <div class="mt-4">
                                <div class="flex space-x-4 mb-4">
                                    <button 
                                        type="button" 
                                        class="px-4 py-2 text-sm font-medium rounded-md {{ $uploadType === 'file' ? 'bg-primary text-white' : 'bg-gray-200 text-gray-700' }}"
                                        wire:click="setUploadType('file')"
                                    >
                                        Upload File
                                    </button>
                                    <button 
                                        type="button" 
                                        class="px-4 py-2 text-sm font-medium rounded-md {{ $uploadType === 'url' ? 'bg-primary text-white' : 'bg-gray-200 text-gray-700' }}"
                                        wire:click="setUploadType('url')"
                                    >
                                        Use URL
                                    </button>
                                </div>
                                
                                @if($uploadType === 'file')
                                    <div 
                                        x-data="{ isUploading: false, progress: 0 }"
                                        x-on:livewire-upload-start="isUploading = true"
                                        x-on:livewire-upload-finish="isUploading = false"
                                        x-on:livewire-upload-error="isUploading = false"
                                        x-on:livewire-upload-progress="progress = $event.detail.progress"
                                    >
                                        <label class="block text-sm font-medium text-gray-700">
                                            Upload a new avatar
                                        </label>
                                        <div class="mt-1 flex justify-center px-6 pt-5 pb-6 border-2 border-gray-300 border-dashed rounded-md">
                                            <div class="space-y-1 text-center">
                                                <svg class="mx-auto h-12 w-12 text-gray-400" stroke="currentColor" fill="none" viewBox="0 0 48 48" aria-hidden="true">
                                                    <path d="M28 8H12a4 4 0 00-4 4v20m32-12v8m0 0v8a4 4 0 01-4 4H12a4 4 0 01-4-4v-4m32-4l-3.172-3.172a4 4 0 00-5.656 0L28 28M8 32l9.172-9.172a4 4 0 015.656 0L28 28m0 0l4 4m4-24h8m-4-4v8m-12 4h.02" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />
                                                </svg>
                                                <div class="flex text-sm text-gray-600">
                                                    <label for="avatar" class="relative cursor-pointer bg-white rounded-md font-medium text-primary hover:text-primary-dark focus-within:outline-none focus-within:ring-2 focus-within:ring-offset-2 focus-within:ring-primary">
                                                        <span>Upload a file</span>
                                                        <input id="avatar" wire:model="avatar" type="file" class="sr-only">
                                                    </label>
                                                    <p class="pl-1">or drag and drop</p>
                                                </div>
                                                <p class="text-xs text-gray-500">
                                                    PNG, JPG, GIF up to 1MB
                                                </p>
                                            </div>
                                        </div>
                                        
                                        <!-- Progress Bar -->
                                        <div x-show="isUploading" class="mt-2">
                                            <div class="h-2 bg-gray-200 rounded-full">
                                                <div class="h-2 bg-primary rounded-full" :style="`width: ${progress}%`"></div>
                                            </div>
                                        </div>
                                        
                                        @error('avatar') <span class="text-red-500 text-sm">{{ $message }}</span> @enderror
                                        
                                        @if($avatar)
                                            <div class="mt-4">
                                                <p class="text-sm font-medium text-gray-700">Preview:</p>
                                                <img src="{{ $avatar->temporaryUrl() }}" alt="Avatar preview" class="mt-2 h-20 w-20 rounded-full object-cover">
                                            </div>
                                        @endif
                                    </div>
                                @else
                                    <div>
                                        <label for="avatarUrl" class="block text-sm font-medium text-gray-700">
                                            Avatar URL
                                        </label>
                                        <div class="mt-1">
                                            <input 
                                                type="text" 
                                                id="avatarUrl" 
                                                wire:model.defer="avatarUrl" 
                                                class="shadow-sm focus:ring-primary focus:border-primary block w-full sm:text-sm border-gray-300 rounded-md"
                                                placeholder="https://example.com/avatar.jpg"
                                            >
                                        </div>
                                        @error('avatarUrl') <span class="text-red-500 text-sm">{{ $message }}</span> @enderror
                                        
                                        @if($avatarUrl)
                                            <div class="mt-4">
                                                <p class="text-sm font-medium text-gray-700">Preview:</p>
                                                <img 
                                                    src="{{ $avatarUrl }}" 
                                                    alt="Avatar preview" 
                                                    class="mt-2 h-20 w-20 rounded-full object-cover"
                                                    onerror="this.src='https://ui-avatars.com/api/?name={{ urlencode(auth()->user()->name) }}'; this.onerror=null;"
                                                >
                                            </div>
                                        @endif
                                    </div>
                                @endif
                            </div>
                        </div>
                    </div>
                </div>
                <div class="bg-gray-50 px-4 py-3 sm:px-6 sm:flex sm:flex-row-reverse">
                    <button 
                        type="button" 
                        wire:click="save" 
                        class="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-primary text-base font-medium text-white hover:bg-primary-dark focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary sm:ml-3 sm:w-auto sm:text-sm"
                    >
                        Save
                    </button>
                    <button 
                        type="button" 
                        wire:click="closeModal" 
                        class="mt-3 w-full inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary sm:mt-0 sm:ml-3 sm:w-auto sm:text-sm"
                    >
                        Cancel
                    </button>
                    @if(auth()->user()->avatar_url)
                        <button 
                            type="button" 
                            wire:click="deleteAvatar" 
                            class="mt-3 w-full inline-flex justify-center rounded-md border border-red-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-red-700 hover:bg-red-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500 sm:mt-0 sm:w-auto sm:text-sm"
                        >
                            Remove
                        </button>
                    @endif
                </div>
            </div>
        </div>
    </div>
    @endif
</div>
