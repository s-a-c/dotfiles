<?php

namespace App\Http\Livewire;

use Livewire\Component;
use Livewire\WithFileUploads;

class RegisterAvatar extends Component
{
    use WithFileUploads;

    public $avatar;
    public $avatarUrl;
    public $uploadType = 'none'; // 'none', 'file', or 'url'
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
    public function updatedAvatar()
    {
        $this->validate([
            'avatar' => 'image|max:1024', // 1MB max
        ]);
<<<<<<< HEAD

        $this->uploadType = 'file';
        $this->avatarUrl = null;
    }

=======
        
        $this->uploadType = 'file';
        $this->avatarUrl = null;
    }
    
>>>>>>> origin/develop
    public function updatedAvatarUrl()
    {
        $this->validate([
            'avatarUrl' => 'url',
        ]);
<<<<<<< HEAD

        $this->uploadType = 'url';
        $this->avatar = null;
    }

=======
        
        $this->uploadType = 'url';
        $this->avatar = null;
    }
    
>>>>>>> origin/develop
    public function removeAvatar()
    {
        $this->avatar = null;
        $this->avatarUrl = null;
        $this->uploadType = 'none';
    }
<<<<<<< HEAD

=======
    
>>>>>>> origin/develop
    public function getAvatarDataProperty()
    {
        if ($this->uploadType === 'file' && $this->avatar) {
            return [
                'type' => 'file',
                'file' => $this->avatar,
            ];
        }
<<<<<<< HEAD

=======
        
>>>>>>> origin/develop
        if ($this->uploadType === 'url' && $this->avatarUrl) {
            return [
                'type' => 'url',
                'url' => $this->avatarUrl,
            ];
        }
<<<<<<< HEAD

        return null;
    }

=======
        
        return null;
    }
    
>>>>>>> origin/develop
    public function render()
    {
        return view('livewire.register-avatar');
    }
}
