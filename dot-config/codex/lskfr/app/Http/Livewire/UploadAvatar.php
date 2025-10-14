<?php

namespace App\Http\Livewire;

use Illuminate\Support\Facades\Auth;
use Livewire\Component;
use Livewire\WithFileUploads;

class UploadAvatar extends Component
{
    use WithFileUploads;

    public $avatar;
    public $avatarUrl;
    public $showModal = false;
    public $uploadType = 'file'; // 'file' or 'url'
<<<<<<< HEAD

=======
    
>>>>>>> origin/develop
    protected $rules = [
        'avatar' => 'nullable|image|max:1024', // 1MB max
        'avatarUrl' => 'nullable|url',
    ];
<<<<<<< HEAD

=======
    
>>>>>>> origin/develop
    public function mount()
    {
        $user = Auth::user();
        $this->avatarUrl = $user->attributes['avatar'] ?? '';
    }
<<<<<<< HEAD

=======
    
>>>>>>> origin/develop
    public function updatedAvatar()
    {
        $this->validate([
            'avatar' => 'image|max:1024', // 1MB max
        ]);
    }
<<<<<<< HEAD

=======
    
>>>>>>> origin/develop
    public function updatedAvatarUrl()
    {
        $this->validate([
            'avatarUrl' => 'url',
        ]);
    }
<<<<<<< HEAD

    public function save()
    {
        $user = Auth::user();

        if ($this->uploadType === 'file' && $this->avatar) {
            // Clear any existing avatar media
            $user->clearMediaCollection('avatar');

=======
    
    public function save()
    {
        $user = Auth::user();
        
        if ($this->uploadType === 'file' && $this->avatar) {
            // Clear any existing avatar media
            $user->clearMediaCollection('avatar');
            
>>>>>>> origin/develop
            // Add the new avatar
            $user->addMedia($this->avatar->getRealPath())
                ->usingName('avatar')
                ->usingFileName($this->avatar->getClientOriginalName())
                ->toMediaCollection('avatar');
<<<<<<< HEAD

            // Clear the avatar URL field
            $user->avatar = null;
            $user->save();

            $this->avatar = null;
            $this->emit('avatarUpdated');
            $this->showModal = false;

=======
                
            // Clear the avatar URL field
            $user->avatar = null;
            $user->save();
            
            $this->avatar = null;
            $this->emit('avatarUpdated');
            $this->showModal = false;
            
>>>>>>> origin/develop
            session()->flash('message', 'Avatar uploaded successfully!');
        } elseif ($this->uploadType === 'url' && $this->avatarUrl) {
            $this->validate([
                'avatarUrl' => 'url',
            ]);
<<<<<<< HEAD

            // Clear any existing avatar media
            $user->clearMediaCollection('avatar');

            // Set the avatar URL
            $user->avatar = $this->avatarUrl;
            $user->save();

            $this->emit('avatarUpdated');
            $this->showModal = false;

            session()->flash('message', 'Avatar URL updated successfully!');
        }
    }

    public function deleteAvatar()
    {
        $user = Auth::user();

        // Clear any existing avatar media
        $user->clearMediaCollection('avatar');

        // Clear the avatar URL field
        $user->avatar = null;
        $user->save();

=======
            
            // Clear any existing avatar media
            $user->clearMediaCollection('avatar');
            
            // Set the avatar URL
            $user->avatar = $this->avatarUrl;
            $user->save();
            
            $this->emit('avatarUpdated');
            $this->showModal = false;
            
            session()->flash('message', 'Avatar URL updated successfully!');
        }
    }
    
    public function deleteAvatar()
    {
        $user = Auth::user();
        
        // Clear any existing avatar media
        $user->clearMediaCollection('avatar');
        
        // Clear the avatar URL field
        $user->avatar = null;
        $user->save();
        
>>>>>>> origin/develop
        $this->avatar = null;
        $this->avatarUrl = '';
        $this->emit('avatarUpdated');
        $this->showModal = false;
<<<<<<< HEAD

        session()->flash('message', 'Avatar removed successfully!');
    }

=======
        
        session()->flash('message', 'Avatar removed successfully!');
    }
    
>>>>>>> origin/develop
    public function openModal()
    {
        $this->showModal = true;
    }
<<<<<<< HEAD

=======
    
>>>>>>> origin/develop
    public function closeModal()
    {
        $this->showModal = false;
        $this->avatar = null;
        $this->resetValidation();
    }
<<<<<<< HEAD

=======
    
>>>>>>> origin/develop
    public function setUploadType($type)
    {
        $this->uploadType = $type;
        $this->resetValidation();
    }
<<<<<<< HEAD

=======
    
>>>>>>> origin/develop
    public function render()
    {
        return view('livewire.upload-avatar');
    }
}
