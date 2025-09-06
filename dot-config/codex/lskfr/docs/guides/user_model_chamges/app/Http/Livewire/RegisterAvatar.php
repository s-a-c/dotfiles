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

    protected $rules = [
        'avatar' => 'nullable|image|max:1024', // 1MB max
        'avatarUrl' => 'nullable|url',
    ];

    public function updatedAvatar()
    {
        $this->validate([
            'avatar' => 'image|max:1024', // 1MB max
        ]);

        $this->uploadType = 'file';
        $this->avatarUrl = null;
    }

    public function updatedAvatarUrl()
    {
        $this->validate([
            'avatarUrl' => 'url',
        ]);

        $this->uploadType = 'url';
        $this->avatar = null;
    }

    public function removeAvatar()
    {
        $this->avatar = null;
        $this->avatarUrl = null;
        $this->uploadType = 'none';
    }

    public function getAvatarDataProperty()
    {
        if ($this->uploadType === 'file' && $this->avatar) {
            return [
                'type' => 'file',
                'file' => $this->avatar,
            ];
        }

        if ($this->uploadType === 'url' && $this->avatarUrl) {
            return [
                'type' => 'url',
                'url' => $this->avatarUrl,
            ];
        }

        return null;
    }

    public function render()
    {
        return view('livewire.register-avatar');
    }
}
