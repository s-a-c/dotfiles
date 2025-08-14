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
    
    protected $rules = [
        'avatar' => 'nullable|image|max:1024', // 1MB max
        'avatarUrl' => 'nullable|url',
    ];
    
    public function mount()
    {
        $user = Auth::user();
        $this->avatarUrl = $user->attributes['avatar'] ?? '';
    }
    
    public function updatedAvatar()
    {
        $this->validate([
            'avatar' => 'image|max:1024', // 1MB max
        ]);
    }
    
    public function updatedAvatarUrl()
    {
        $this->validate([
            'avatarUrl' => 'url',
        ]);
    }
    
    public function save()
    {
        $user = Auth::user();
        
        if ($this->uploadType === 'file' && $this->avatar) {
            // Clear any existing avatar media
            $user->clearMediaCollection('avatar');
            
            // Add the new avatar
            $user->addMedia($this->avatar->getRealPath())
                ->usingName('avatar')
                ->usingFileName($this->avatar->getClientOriginalName())
                ->toMediaCollection('avatar');
                
            // Clear the avatar URL field
            $user->avatar = null;
            $user->save();
            
            $this->avatar = null;
            $this->emit('avatarUpdated');
            $this->showModal = false;
            
            session()->flash('message', 'Avatar uploaded successfully!');
        } elseif ($this->uploadType === 'url' && $this->avatarUrl) {
            $this->validate([
                'avatarUrl' => 'url',
            ]);
            
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
        
        $this->avatar = null;
        $this->avatarUrl = '';
        $this->emit('avatarUpdated');
        $this->showModal = false;
        
        session()->flash('message', 'Avatar removed successfully!');
    }
    
    public function openModal()
    {
        $this->showModal = true;
    }
    
    public function closeModal()
    {
        $this->showModal = false;
        $this->avatar = null;
        $this->resetValidation();
    }
    
    public function setUploadType($type)
    {
        $this->uploadType = $type;
        $this->resetValidation();
    }
    
    public function render()
    {
        return view('livewire.upload-avatar');
    }
}
