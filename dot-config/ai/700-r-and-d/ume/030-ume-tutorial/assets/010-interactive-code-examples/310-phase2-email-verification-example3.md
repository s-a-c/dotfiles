# Email Verification Process

:::interactive-code
title: Implementing Email Verification with Tokens
description: This example demonstrates how to implement a complete email verification process with tokens, expiration, and resending capabilities.
language: php
editable: true
code: |
  <?php
  
  namespace App\Services;
  
  use DateInterval;
  use DateTime;
  use Exception;
  
  class EmailVerificationService {
      // Token expiration time (24 hours)
      private const TOKEN_EXPIRATION = 'P1D';
      
      // Store tokens in memory (in a real app, this would be a database)
      private $tokens = [];
      
      /**
       * Generate a verification token for a user.
       *
       * @param int $userId
       * @param string $email
       * @return string
       */
      public function generateToken(int $userId, string $email): string {
          // Generate a random token
          $token = bin2hex(random_bytes(32));
          
          // Calculate expiration time
          $expiresAt = (new DateTime())->add(new DateInterval(self::TOKEN_EXPIRATION));
          
          // Store the token
          $this->tokens[$token] = [
              'user_id' => $userId,
              'email' => $email,
              'created_at' => new DateTime(),
              'expires_at' => $expiresAt,
              'verified_at' => null,
          ];
          
          return $token;
      }
      
      /**
       * Send a verification email to the user.
       *
       * @param int $userId
       * @param string $email
       * @return string The generated token
       */
      public function sendVerificationEmail(int $userId, string $email): string {
          // Generate a token
          $token = $this->generateToken($userId, $email);
          
          // In a real app, this would send an actual email
          echo "Sending verification email to {$email}\n";
          echo "Verification link: https://example.com/verify-email/{$token}\n";
          
          return $token;
      }
      
      /**
       * Verify a token.
       *
       * @param string $token
       * @return array|null The verified user data or null if invalid
       * @throws Exception If the token is expired or already verified
       */
      public function verifyToken(string $token): ?array {
          // Check if the token exists
          if (!isset($this->tokens[$token])) {
              throw new Exception('Invalid verification token');
          }
          
          $tokenData = $this->tokens[$token];
          
          // Check if the token is already verified
          if ($tokenData['verified_at'] !== null) {
              throw new Exception('Token has already been verified');
          }
          
          // Check if the token is expired
          $now = new DateTime();
          if ($now > $tokenData['expires_at']) {
              throw new Exception('Token has expired');
          }
          
          // Mark the token as verified
          $this->tokens[$token]['verified_at'] = $now;
          
          return [
              'user_id' => $tokenData['user_id'],
              'email' => $tokenData['email'],
          ];
      }
      
      /**
       * Check if a user's email is verified.
       *
       * @param int $userId
       * @param string $email
       * @return bool
       */
      public function isEmailVerified(int $userId, string $email): bool {
          foreach ($this->tokens as $tokenData) {
              if ($tokenData['user_id'] === $userId && 
                  $tokenData['email'] === $email && 
                  $tokenData['verified_at'] !== null) {
                  return true;
              }
          }
          
          return false;
      }
      
      /**
       * Resend a verification email.
       *
       * @param int $userId
       * @param string $email
       * @return string The new token
       * @throws Exception If the email is already verified
       */
      public function resendVerificationEmail(int $userId, string $email): string {
          // Check if the email is already verified
          if ($this->isEmailVerified($userId, $email)) {
              throw new Exception('Email is already verified');
          }
          
          // Invalidate any existing tokens for this user and email
          foreach ($this->tokens as $token => $tokenData) {
              if ($tokenData['user_id'] === $userId && $tokenData['email'] === $email) {
                  unset($this->tokens[$token]);
              }
          }
          
          // Send a new verification email
          return $this->sendVerificationEmail($userId, $email);
      }
      
      /**
       * Get token data for debugging.
       *
       * @param string $token
       * @return array|null
       */
      public function getTokenData(string $token): ?array {
          return $this->tokens[$token] ?? null;
      }
  }
  
  // User model
  class User {
      public $id;
      public $name;
      public $email;
      public $email_verified_at;
      
      public function __construct(int $id, string $name, string $email) {
          $this->id = $id;
          $this->name = $name;
          $this->email = $email;
          $this->email_verified_at = null;
      }
      
      public function markEmailAsVerified(): void {
          $this->email_verified_at = new DateTime();
      }
      
      public function hasVerifiedEmail(): bool {
          return $this->email_verified_at !== null;
      }
  }
  
  // Example usage
  $verificationService = new EmailVerificationService();
  
  // Create a user
  $user = new User(1, 'John Doe', 'john@example.com');
  echo "User created: {$user->name} ({$user->email})\n";
  echo "Email verified: " . ($user->hasVerifiedEmail() ? 'Yes' : 'No') . "\n";
  
  // Send verification email
  echo "\nSending verification email...\n";
  $token = $verificationService->sendVerificationEmail($user->id, $user->email);
  
  // Display token data (for debugging)
  echo "\nToken data:\n";
  $tokenData = $verificationService->getTokenData($token);
  echo "- Created at: " . $tokenData['created_at']->format('Y-m-d H:i:s') . "\n";
  echo "- Expires at: " . $tokenData['expires_at']->format('Y-m-d H:i:s') . "\n";
  echo "- Verified at: " . ($tokenData['verified_at'] ? $tokenData['verified_at']->format('Y-m-d H:i:s') : 'Not verified') . "\n";
  
  // Verify the token
  echo "\nVerifying token...\n";
  try {
      $userData = $verificationService->verifyToken($token);
      echo "Token verified for user ID: {$userData['user_id']}, Email: {$userData['email']}\n";
      
      // Update the user model
      $user->markEmailAsVerified();
      echo "User email marked as verified\n";
      echo "Email verified: " . ($user->hasVerifiedEmail() ? 'Yes' : 'No') . "\n";
  } catch (Exception $e) {
      echo "Error: " . $e->getMessage() . "\n";
  }
  
  // Try to verify the same token again
  echo "\nTrying to verify the same token again...\n";
  try {
      $verificationService->verifyToken($token);
  } catch (Exception $e) {
      echo "Error: " . $e->getMessage() . "\n";
  }
  
  // Try to resend verification email for an already verified email
  echo "\nTrying to resend verification email for an already verified email...\n";
  try {
      $verificationService->resendVerificationEmail($user->id, $user->email);
  } catch (Exception $e) {
      echo "Error: " . $e->getMessage() . "\n";
  }
  
  // Create another user and demonstrate token expiration
  $user2 = new User(2, 'Jane Smith', 'jane@example.com');
  echo "\nUser created: {$user2->name} ({$user2->email})\n";
  
  // Send verification email
  echo "Sending verification email...\n";
  $token2 = $verificationService->sendVerificationEmail($user2->id, $user2->email);
  
  // Simulate token expiration by modifying the token data
  echo "Simulating token expiration...\n";
  $tokenData = $verificationService->getTokenData($token2);
  $tokenData['expires_at'] = (new DateTime())->sub(new DateInterval('PT1H')); // 1 hour ago
  $verificationService->tokens[$token2] = $tokenData;
  
  // Try to verify the expired token
  echo "Trying to verify the expired token...\n";
  try {
      $verificationService->verifyToken($token2);
  } catch (Exception $e) {
      echo "Error: " . $e->getMessage() . "\n";
  }
  
  // Resend verification email
  echo "\nResending verification email...\n";
  $newToken = $verificationService->resendVerificationEmail($user2->id, $user2->email);
  
  // Verify the new token
  echo "Verifying the new token...\n";
  try {
      $userData = $verificationService->verifyToken($newToken);
      echo "Token verified for user ID: {$userData['user_id']}, Email: {$userData['email']}\n";
      
      // Update the user model
      $user2->markEmailAsVerified();
      echo "User email marked as verified\n";
      echo "Email verified: " . ($user2->hasVerifiedEmail() ? 'Yes' : 'No') . "\n";
  } catch (Exception $e) {
      echo "Error: " . $e->getMessage() . "\n";
  }
explanation: |
  This example demonstrates a complete email verification process:
  
  1. **Token Generation**: The `EmailVerificationService` generates secure random tokens for email verification.
  
  2. **Token Storage**: Tokens are stored with metadata including:
     - User ID
     - Email address
     - Creation timestamp
     - Expiration timestamp
     - Verification timestamp
  
  3. **Email Sending**: The service simulates sending verification emails with links containing the token.
  
  4. **Token Verification**: When a user clicks the verification link, the token is validated:
     - Checks if the token exists
     - Checks if the token has already been used
     - Checks if the token has expired
     - Marks the token as verified if valid
  
  5. **Email Status Tracking**: The User model tracks whether the email has been verified.
  
  6. **Token Expiration**: Tokens expire after a specified period (24 hours in this example).
  
  7. **Resending Capability**: Users can request a new verification email, which invalidates any existing tokens.
  
  In a real Laravel application:
  - Tokens would be stored in a database table
  - Email sending would use Laravel's Mail facade
  - The verification process would be integrated with Laravel's authentication system
  - Token generation and verification would be handled by middleware
  - The User model would use the `MustVerifyEmail` interface
challenges:
  - Add a method to track failed verification attempts and limit them
  - Implement a notification system that reminds users to verify their email after a certain period
  - Create a dashboard for administrators to view and manage verification statuses
  - Add support for verifying a new email address when a user changes their email
  - Implement a secure method for users to request a new verification link without being logged in
:::
