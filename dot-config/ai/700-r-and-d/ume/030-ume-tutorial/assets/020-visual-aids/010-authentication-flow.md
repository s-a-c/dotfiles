# Authentication Flow

<link rel="stylesheet" href="../css/styles.css">
<link rel="stylesheet" href="../css/ume-docs-enhancements.css">
<script src="../js/ume-docs-enhancements.js"></script>

## Overview

This visual aid illustrates the authentication flow in the UME system, including standard login, two-factor authentication, and API token authentication with Laravel Sanctum.

## Standard Authentication Flow

The following sequence diagram shows the standard authentication flow for web-based login:

```mermaid
%%{init: {'theme': 'base', 'themeVariables': {'primaryColor': '#f3f4f6', 'lineColor': '#6b7280', 'textColor': '#111827', 'mainBkg': '#ffffff', 'secondaryColor': '#60a5fa', 'tertiaryColor': '#e5e7eb'}}}%%
sequenceDiagram
    actor User
    participant Browser
    participant LoginController
    participant AuthManager
    participant UserModel
    participant SessionManager
    
    User->>Browser: Enter credentials
    Browser->>LoginController: POST /login
    LoginController->>AuthManager: attempt(credentials)
    AuthManager->>UserModel: findByEmail(email)
    UserModel-->>AuthManager: User instance
    AuthManager->>UserModel: checkPassword(password)
    
    alt Invalid credentials
        UserModel-->>AuthManager: false
        AuthManager-->>LoginController: false
        LoginController-->>Browser: Redirect with errors
        Browser-->>User: Show error message
    else Valid credentials
        UserModel-->>AuthManager: true
        AuthManager->>UserModel: checkStatus()
        
        alt Account not active
            UserModel-->>AuthManager: false (inactive)
            AuthManager-->>LoginController: false
            LoginController-->>Browser: Redirect with status error
            Browser-->>User: Show account status message
        else Account active
            UserModel-->>AuthManager: true
            AuthManager->>SessionManager: create(user)
            SessionManager-->>AuthManager: session created
            AuthManager-->>LoginController: true
            
            alt 2FA enabled
                LoginController-->>Browser: Redirect to 2FA challenge
                Browser-->>User: Show 2FA input
            else 2FA disabled
                LoginController-->>Browser: Redirect to dashboard
                Browser-->>User: Show dashboard
            end
        end
    end
```

<div class="mermaid-caption">Figure 1: Standard Authentication Flow</div>

## Two-Factor Authentication Flow

The following sequence diagram shows the two-factor authentication flow:

```mermaid
%%{init: {'theme': 'base', 'themeVariables': {'primaryColor': '#f3f4f6', 'lineColor': '#6b7280', 'textColor': '#111827', 'mainBkg': '#ffffff', 'secondaryColor': '#60a5fa', 'tertiaryColor': '#e5e7eb'}}}%%
sequenceDiagram
    actor User
    participant Browser
    participant TwoFactorController
    participant AuthManager
    participant TwoFactorProvider
    participant UserModel
    
    User->>Browser: Enter 2FA code
    Browser->>TwoFactorController: POST /two-factor-challenge
    TwoFactorController->>AuthManager: getTwoFactorProvider()
    AuthManager-->>TwoFactorController: TwoFactorProvider
    TwoFactorController->>TwoFactorProvider: verify(user, code)
    
    alt Invalid code
        TwoFactorProvider-->>TwoFactorController: false
        TwoFactorController-->>Browser: Redirect with errors
        Browser-->>User: Show error message
    else Valid code
        TwoFactorProvider-->>TwoFactorController: true
        TwoFactorController->>UserModel: markTwoFactorComplete()
        UserModel-->>TwoFactorController: success
        TwoFactorController-->>Browser: Redirect to intended page
        Browser-->>User: Show intended page
    end
```

<div class="mermaid-caption">Figure 2: Two-Factor Authentication Flow</div>

## API Token Authentication Flow

The following sequence diagram shows the API token authentication flow using Laravel Sanctum:

```mermaid
%%{init: {'theme': 'base', 'themeVariables': {'primaryColor': '#f3f4f6', 'lineColor': '#6b7280', 'textColor': '#111827', 'mainBkg': '#ffffff', 'secondaryColor': '#60a5fa', 'tertiaryColor': '#e5e7eb'}}}%%
sequenceDiagram
    participant Client
    participant TokenController
    participant AuthManager
    participant UserModel
    participant SanctumTokenManager
    participant ProtectedEndpoint
    
    Client->>TokenController: POST /api/token (credentials)
    TokenController->>AuthManager: attempt(credentials)
    AuthManager->>UserModel: findByEmail(email)
    UserModel-->>AuthManager: User instance
    AuthManager->>UserModel: checkPassword(password)
    
    alt Invalid credentials
        UserModel-->>AuthManager: false
        AuthManager-->>TokenController: false
        TokenController-->>Client: 401 Unauthorized
    else Valid credentials
        UserModel-->>AuthManager: true
        TokenController->>SanctumTokenManager: createToken(user, name, abilities)
        SanctumTokenManager-->>TokenController: token
        TokenController-->>Client: 200 OK with token
        
        Note over Client,TokenController: Later API requests
        
        Client->>ProtectedEndpoint: Request with Bearer token
        ProtectedEndpoint->>SanctumTokenManager: validateToken(token)
        SanctumTokenManager->>UserModel: findForToken(token)
        UserModel-->>SanctumTokenManager: User instance
        SanctumTokenManager->>SanctumTokenManager: checkAbilities(token, abilities)
        
        alt Valid token with required abilities
            SanctumTokenManager-->>ProtectedEndpoint: User instance
            ProtectedEndpoint-->>Client: 200 OK with data
        else Invalid token or missing abilities
            SanctumTokenManager-->>ProtectedEndpoint: null
            ProtectedEndpoint-->>Client: 401 Unauthorized
        end
    end
```

<div class="mermaid-caption">Figure 3: API Token Authentication Flow</div>

## Password Reset Flow

The following sequence diagram shows the password reset flow:

```mermaid
%%{init: {'theme': 'base', 'themeVariables': {'primaryColor': '#f3f4f6', 'lineColor': '#6b7280', 'textColor': '#111827', 'mainBkg': '#ffffff', 'secondaryColor': '#60a5fa', 'tertiaryColor': '#e5e7eb'}}}%%
sequenceDiagram
    actor User
    participant Browser
    participant PasswordResetController
    participant PasswordBroker
    participant UserModel
    participant Mailer
    
    %% Request password reset
    User->>Browser: Enter email for reset
    Browser->>PasswordResetController: POST /forgot-password
    PasswordResetController->>PasswordBroker: sendResetLink(email)
    PasswordBroker->>UserModel: findByEmail(email)
    
    alt User not found
        UserModel-->>PasswordBroker: null
        PasswordBroker-->>PasswordResetController: UserNotFound
        PasswordResetController-->>Browser: Redirect with generic message
        Browser-->>User: Show message (security by obscurity)
    else User found
        UserModel-->>PasswordBroker: User instance
        PasswordBroker->>PasswordBroker: createToken(user)
        PasswordBroker->>Mailer: send(ResetPasswordMail)
        Mailer-->>PasswordBroker: success
        PasswordBroker-->>PasswordResetController: success
        PasswordResetController-->>Browser: Redirect with success message
        Browser-->>User: Show success message
        
        %% Reset password
        User->>Browser: Click reset link in email
        Browser->>PasswordResetController: GET /reset-password/{token}
        PasswordResetController-->>Browser: Show reset form
        Browser-->>User: Display reset form
        
        User->>Browser: Enter new password
        Browser->>PasswordResetController: POST /reset-password
        PasswordResetController->>PasswordBroker: reset(credentials, callback)
        PasswordBroker->>UserModel: findByEmail(email)
        UserModel-->>PasswordBroker: User instance
        PasswordBroker->>PasswordBroker: validateToken(user, token)
        
        alt Invalid token
            PasswordBroker-->>PasswordResetController: InvalidToken
            PasswordResetController-->>Browser: Redirect with error
            Browser-->>User: Show error message
        else Valid token
            PasswordBroker->>UserModel: updatePassword(password)
            UserModel-->>PasswordBroker: success
            PasswordBroker-->>PasswordResetController: success
            PasswordResetController-->>Browser: Redirect to login
            Browser-->>User: Show login form with success message
        end
    end
```

<div class="mermaid-caption">Figure 4: Password Reset Flow</div>

## Authentication Components

The UME system uses several components to implement authentication:

```mermaid
%%{init: {'theme': 'base', 'themeVariables': {'primaryColor': '#f3f4f6', 'lineColor': '#6b7280', 'textColor': '#111827', 'mainBkg': '#ffffff', 'secondaryColor': '#60a5fa', 'tertiaryColor': '#e5e7eb'}}}%%
graph TD
    Auth[Authentication System] --> Web[Web Authentication]
    Auth --> API[API Authentication]
    Auth --> TwoFactor[Two-Factor Authentication]
    
    Web --> Session[Session Authentication]
    Web --> Remember[Remember Me]
    Web --> PasswordReset[Password Reset]
    
    API --> Sanctum[Laravel Sanctum]
    API --> TokenAbilities[Token Abilities]
    API --> CSRF[CSRF Protection]
    
    TwoFactor --> TOTP[Time-based OTP]
    TwoFactor --> Recovery[Recovery Codes]
    TwoFactor --> WebAuthn[WebAuthn/FIDO2]
    
    Session --> Guards[Authentication Guards]
    Guards --> WebGuard[Web Guard]
    Guards --> ApiGuard[API Guard]
    
    Sanctum --> SPA[SPA Authentication]
    Sanctum --> Mobile[Mobile Authentication]
    Sanctum --> ThirdParty[Third-party API]
```

<div class="mermaid-caption">Figure 5: Authentication Components</div>

## Related Resources

- [Authentication Implementation](../../050-implementation/030-phase2-auth-profile/010-authentication.md)
- [Two-Factor Authentication](../../050-implementation/030-phase2-auth-profile/020-two-factor-auth.md)
- [API Authentication](../../050-implementation/030-phase2-auth-profile/030-api-authentication.md)
- [Laravel Authentication Documentation](https://laravel.com/docs/authentication)
- [Laravel Sanctum Documentation](https://laravel.com/docs/sanctum)
- [Diagram Style Guide](./diagram-style-guide.md)
