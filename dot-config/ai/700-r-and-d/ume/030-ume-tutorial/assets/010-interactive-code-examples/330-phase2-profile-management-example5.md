# Profile Management

:::interactive-code
title: Implementing User Profile Management
description: This example demonstrates how to implement a comprehensive user profile management system with avatar handling and profile completion tracking.
language: php
editable: true
code: |
  <?php
  
  namespace App\Models;
  
  use DateTime;
  use Exception;
  
  class User {
      public int $id;
      public string $name;
      public string $email;
      public ?string $email_verified_at;
      
      public function __construct(int $id, string $name, string $email) {
          $this->id = $id;
          $this->name = $name;
          $this->email = $email;
          $this->email_verified_at = null;
      }
      
      public function profile() {
          return new Profile($this);
      }
  }
  
  class Profile {
      private User $user;
      private array $data = [];
      private ?string $avatarPath = null;
      private array $socialLinks = [];
      private array $requiredFields = ['bio', 'location', 'phone'];
      private array $optionalFields = ['website', 'company', 'job_title', 'birthday'];
      
      public function __construct(User $user) {
          $this->user = $user;
      }
      
      /**
       * Get a profile field.
       *
       * @param string $field
       * @return mixed|null
       */
      public function get(string $field) {
          return $this->data[$field] ?? null;
      }
      
      /**
       * Set a profile field.
       *
       * @param string $field
       * @param mixed $value
       * @return self
       */
      public function set(string $field, $value): self {
          $this->data[$field] = $value;
          return $this;
      }
      
      /**
       * Set multiple profile fields.
       *
       * @param array $data
       * @return self
       */
      public function update(array $data): self {
          foreach ($data as $field => $value) {
              $this->set($field, $value);
          }
          
          return $this;
      }
      
      /**
       * Get all profile data.
       *
       * @return array
       */
      public function getData(): array {
          return $this->data;
      }
      
      /**
       * Get the user's avatar path.
       *
       * @return string|null
       */
      public function getAvatarPath(): ?string {
          return $this->avatarPath;
      }
      
      /**
       * Get the user's avatar URL.
       *
       * @return string
       */
      public function getAvatarUrl(): string {
          if ($this->avatarPath) {
              return "https://example.com/storage/avatars/{$this->avatarPath}";
          }
          
          // Return default avatar based on user's initials
          $initials = strtoupper(substr($this->user->name, 0, 1));
          return "https://ui-avatars.com/api/?name={$initials}&color=7F9CF5&background=EBF4FF";
      }
      
      /**
       * Upload and set the user's avatar.
       *
       * @param array $file Uploaded file data
       * @return self
       * @throws Exception If the file is invalid
       */
      public function setAvatar(array $file): self {
          // Validate the file (in a real app, this would check MIME type, size, etc.)
          if (!isset($file['name']) || !isset($file['tmp_name'])) {
              throw new Exception('Invalid file data');
          }
          
          // Generate a unique filename
          $filename = $this->user->id . '_' . time() . '_' . $file['name'];
          
          // In a real app, this would move the uploaded file to the storage location
          // move_uploaded_file($file['tmp_name'], '/path/to/storage/avatars/' . $filename);
          
          // Store the avatar path
          $this->avatarPath = $filename;
          
          echo "Avatar uploaded: {$filename}\n";
          
          return $this;
      }
      
      /**
       * Remove the user's avatar.
       *
       * @return self
       */
      public function removeAvatar(): self {
          if ($this->avatarPath) {
              // In a real app, this would delete the file
              // unlink('/path/to/storage/avatars/' . $this->avatarPath);
              
              echo "Avatar removed: {$this->avatarPath}\n";
              $this->avatarPath = null;
          }
          
          return $this;
      }
      
      /**
       * Add a social media link.
       *
       * @param string $platform
       * @param string $url
       * @return self
       * @throws Exception If the platform or URL is invalid
       */
      public function addSocialLink(string $platform, string $url): self {
          $allowedPlatforms = ['twitter', 'facebook', 'linkedin', 'github', 'instagram'];
          
          if (!in_array(strtolower($platform), $allowedPlatforms)) {
              throw new Exception("Invalid social media platform: {$platform}");
          }
          
          if (!filter_var($url, FILTER_VALIDATE_URL)) {
              throw new Exception("Invalid URL: {$url}");
          }
          
          $this->socialLinks[strtolower($platform)] = $url;
          
          return $this;
      }
      
      /**
       * Remove a social media link.
       *
       * @param string $platform
       * @return self
       */
      public function removeSocialLink(string $platform): self {
          if (isset($this->socialLinks[strtolower($platform)])) {
              unset($this->socialLinks[strtolower($platform)]);
          }
          
          return $this;
      }
      
      /**
       * Get all social media links.
       *
       * @return array
       */
      public function getSocialLinks(): array {
          return $this->socialLinks;
      }
      
      /**
       * Calculate the profile completion percentage.
       *
       * @return int
       */
      public function getCompletionPercentage(): int {
          $totalFields = count($this->requiredFields) + count($this->optionalFields);
          $completedFields = 0;
          
          // Check required fields
          foreach ($this->requiredFields as $field) {
              if (isset($this->data[$field]) && !empty($this->data[$field])) {
                  $completedFields++;
              }
          }
          
          // Check optional fields
          foreach ($this->optionalFields as $field) {
              if (isset($this->data[$field]) && !empty($this->data[$field])) {
                  $completedFields++;
              }
          }
          
          // Add avatar to completion calculation
          if ($this->avatarPath) {
              $completedFields++;
              $totalFields++;
          }
          
          // Add social links to completion calculation
          if (!empty($this->socialLinks)) {
              $completedFields++;
              $totalFields++;
          }
          
          return (int) round(($completedFields / $totalFields) * 100);
      }
      
      /**
       * Check if the profile is complete (all required fields filled).
       *
       * @return bool
       */
      public function isComplete(): bool {
          foreach ($this->requiredFields as $field) {
              if (!isset($this->data[$field]) || empty($this->data[$field])) {
                  return false;
              }
          }
          
          return true;
      }
      
      /**
       * Get missing required fields.
       *
       * @return array
       */
      public function getMissingFields(): array {
          $missingFields = [];
          
          foreach ($this->requiredFields as $field) {
              if (!isset($this->data[$field]) || empty($this->data[$field])) {
                  $missingFields[] = $field;
              }
          }
          
          return $missingFields;
      }
      
      /**
       * Get profile visibility settings.
       *
       * @return array
       */
      public function getVisibilitySettings(): array {
          // In a real app, this would be stored in the database
          return [
              'email' => 'private',
              'phone' => 'friends',
              'location' => 'public',
              'birthday' => 'friends',
              'social_links' => 'public',
          ];
      }
      
      /**
       * Update profile visibility settings.
       *
       * @param array $settings
       * @return self
       */
      public function updateVisibilitySettings(array $settings): self {
          // In a real app, this would update the database
          echo "Visibility settings updated\n";
          return $this;
      }
      
      /**
       * Check if a field is visible to a specific user.
       *
       * @param string $field
       * @param User|null $viewer
       * @return bool
       */
      public function isFieldVisibleTo(string $field, ?User $viewer = null): bool {
          $settings = $this->getVisibilitySettings();
          $visibility = $settings[$field] ?? 'private';
          
          if ($visibility === 'public') {
              return true;
          }
          
          if ($visibility === 'private') {
              return $viewer && $viewer->id === $this->user->id;
          }
          
          if ($visibility === 'friends') {
              // In a real app, this would check if the users are friends
              return $viewer && ($viewer->id === $this->user->id || rand(0, 1) === 1);
          }
          
          return false;
      }
  }
  
  // Example usage
  $user = new User(1, 'John Doe', 'john@example.com');
  $profile = $user->profile();
  
  echo "User: {$user->name} ({$user->email})\n";
  echo "Profile completion: {$profile->getCompletionPercentage()}%\n";
  echo "Profile complete: " . ($profile->isComplete() ? 'Yes' : 'No') . "\n";
  
  if (!$profile->isComplete()) {
      echo "Missing fields: " . implode(', ', $profile->getMissingFields()) . "\n";
  }
  
  // Update profile data
  echo "\nUpdating profile...\n";
  $profile->update([
      'bio' => 'Software developer with 5 years of experience',
      'location' => 'San Francisco, CA',
      'phone' => '+1 (555) 123-4567',
      'website' => 'https://johndoe.com',
      'company' => 'Acme Inc.',
      'job_title' => 'Senior Developer',
  ]);
  
  // Upload avatar
  echo "\nUploading avatar...\n";
  $profile->setAvatar([
      'name' => 'avatar.jpg',
      'tmp_name' => '/tmp/php123456',
  ]);
  
  // Add social links
  echo "\nAdding social links...\n";
  $profile->addSocialLink('github', 'https://github.com/johndoe');
  $profile->addSocialLink('twitter', 'https://twitter.com/johndoe');
  $profile->addSocialLink('linkedin', 'https://linkedin.com/in/johndoe');
  
  // Check profile completion again
  echo "\nProfile completion: {$profile->getCompletionPercentage()}%\n";
  echo "Profile complete: " . ($profile->isComplete() ? 'Yes' : 'No') . "\n";
  
  // Display profile data
  echo "\nProfile data:\n";
  foreach ($profile->getData() as $field => $value) {
      echo "- {$field}: {$value}\n";
  }
  
  // Display social links
  echo "\nSocial links:\n";
  foreach ($profile->getSocialLinks() as $platform => $url) {
      echo "- {$platform}: {$url}\n";
  }
  
  // Display avatar URL
  echo "\nAvatar URL: " . $profile->getAvatarUrl() . "\n";
  
  // Check visibility
  $viewer = new User(2, 'Jane Smith', 'jane@example.com');
  echo "\nVisibility to {$viewer->name}:\n";
  echo "- Email: " . ($profile->isFieldVisibleTo('email', $viewer) ? 'Visible' : 'Hidden') . "\n";
  echo "- Phone: " . ($profile->isFieldVisibleTo('phone', $viewer) ? 'Visible' : 'Hidden') . "\n";
  echo "- Location: " . ($profile->isFieldVisibleTo('location', $viewer) ? 'Visible' : 'Hidden') . "\n";
  
  // Remove avatar
  echo "\nRemoving avatar...\n";
  $profile->removeAvatar();
  
  // Remove a social link
  echo "\nRemoving Twitter link...\n";
  $profile->removeSocialLink('twitter');
  
  // Display social links after removal
  echo "\nSocial links after removal:\n";
  foreach ($profile->getSocialLinks() as $platform => $url) {
      echo "- {$platform}: {$url}\n";
  }
explanation: |
  This example demonstrates a comprehensive user profile management system:
  
  1. **Profile Data Management**: The `Profile` class provides methods to get, set, and update profile fields.
  
  2. **Avatar Handling**: The profile supports uploading, displaying, and removing user avatars.
  
  3. **Social Media Links**: Users can add and remove links to their social media profiles.
  
  4. **Profile Completion Tracking**: The system calculates a completion percentage and identifies missing required fields.
  
  5. **Visibility Settings**: Profile fields can have different visibility levels (public, friends, private).
  
  Key features of the implementation:
  
  - **User-Profile Relationship**: The User model has a `profile()` method that returns a Profile instance.
  
  - **Required vs. Optional Fields**: The profile distinguishes between required fields (needed for profile completion) and optional fields.
  
  - **Fluent Interface**: Methods return `$this` to allow method chaining for a more readable API.
  
  - **Avatar URL Generation**: If no custom avatar is set, a default avatar is generated based on the user's initials.
  
  - **Visibility Control**: The profile includes methods to check if specific fields are visible to specific users.
  
  In a real Laravel application:
  - Profile data would be stored in a separate database table
  - Avatar files would be stored in the filesystem or cloud storage
  - Visibility settings would be stored in the database
  - The system would integrate with Laravel's authentication and authorization
challenges:
  - Add support for multiple avatars or profile images
  - Implement a profile verification system (e.g., for professionals)
  - Create a method to export the profile as a vCard or JSON
  - Add support for custom fields that users can define
  - Implement a profile change history to track when fields were updated
:::
