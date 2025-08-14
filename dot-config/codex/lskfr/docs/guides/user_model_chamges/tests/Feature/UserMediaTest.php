<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class UserMediaTest extends TestCase
{
    use RefreshDatabase;

    public function setUp(): void
    {
        parent::setUp();
        
        // Configure the media disk for testing
        Storage::fake('media');
    }

    public function test_user_can_have_avatar_url()
    {
        $user = User::factory()->create([
            'avatar' => 'https://example.com/avatar.jpg',
        ]);

        $this->assertEquals('https://example.com/avatar.jpg', $user->avatar_url);
    }

    public function test_user_can_upload_avatar_media()
    {
        $user = User::factory()->create();
        
        $file = UploadedFile::fake()->image('avatar.jpg');
        
        $user->addMedia($file)
            ->toMediaCollection('avatar');
            
        $this->assertTrue($user->hasMedia('avatar'));
        $this->assertNotNull($user->getFirstMediaUrl('avatar'));
        $this->assertEquals($user->getFirstMediaUrl('avatar'), $user->avatar_url);
    }

    public function test_user_can_upload_animated_gif_avatar()
    {
        $user = User::factory()->create();
        
        $file = UploadedFile::fake()->image('avatar.gif');
        
        $user->addMedia($file)
            ->toMediaCollection('avatar');
            
        $this->assertTrue($user->hasMedia('avatar'));
        $this->assertNotNull($user->getFirstMediaUrl('avatar'));
        
        // Check that the media has the correct mime type
        $media = $user->getFirstMedia('avatar');
        $this->assertEquals('image/gif', $media->mime_type);
    }

    public function test_avatar_url_prioritizes_media_over_url()
    {
        $user = User::factory()->create([
            'avatar' => 'https://example.com/avatar.jpg',
        ]);
        
        $file = UploadedFile::fake()->image('new-avatar.jpg');
        
        $user->addMedia($file)
            ->toMediaCollection('avatar');
            
        // The avatar_url should return the media URL, not the avatar field
        $this->assertNotEquals('https://example.com/avatar.jpg', $user->avatar_url);
        $this->assertEquals($user->getFirstMediaUrl('avatar'), $user->avatar_url);
    }

    public function test_user_can_get_avatar_thumbnail()
    {
        $user = User::factory()->create();
        
        $file = UploadedFile::fake()->image('avatar.jpg');
        
        $user->addMedia($file)
            ->toMediaCollection('avatar');
            
        $this->assertNotNull($user->avatar_thumb_url);
        $this->assertStringContainsString('thumb', $user->avatar_thumb_url);
    }

    public function test_clearing_media_falls_back_to_avatar_url()
    {
        $user = User::factory()->create([
            'avatar' => 'https://example.com/avatar.jpg',
        ]);
        
        $file = UploadedFile::fake()->image('avatar.jpg');
        
        $user->addMedia($file)
            ->toMediaCollection('avatar');
            
        // Initially, avatar_url should be the media URL
        $this->assertEquals($user->getFirstMediaUrl('avatar'), $user->avatar_url);
        
        // Clear the media
        $user->clearMediaCollection('avatar');
        
        // Now avatar_url should fall back to the avatar field
        $this->assertEquals('https://example.com/avatar.jpg', $user->avatar_url);
    }
}
