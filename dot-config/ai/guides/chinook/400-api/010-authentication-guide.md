# Chinook API Authentication - Complete Guide

> **Created:** 2025-07-18  
> **Focus:** Comprehensive authentication implementation with Laravel Sanctum, multi-factor authentication, and security best practices

## Table of Contents

- [Overview](#overview)
- [Authentication Methods](#authentication-methods)
- [Token Management](#token-management)
- [Multi-Factor Authentication](#multi-factor-authentication)
- [Permission Scopes](#permission-scopes)
- [Security Best Practices](#security-best-practices)
- [Implementation Examples](#implementation-examples)

## Overview

The Chinook API uses Laravel Sanctum for authentication, providing secure token-based authentication with support for multiple device types, token scoping, and multi-factor authentication.

### Authentication Flow

```mermaid
sequenceDiagram
    participant Client
    participant API
    participant Database
    
    Client->>API: POST /api/auth/login
    API->>Database: Validate credentials
    Database-->>API: User validated
    API->>Database: Create token
    Database-->>API: Token created
    API-->>Client: Return token + user data
    
    Client->>API: GET /api/v1/artists (with token)
    API->>Database: Validate token
    Database-->>API: Token valid
    API-->>Client: Return data
```

## Authentication Methods

### 1. Email/Password Authentication

```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "secure_password",
  "device_name": "iPhone 15 Pro",
  "remember_me": true
}
```

**Response:**
```json
{
  "data": {
    "user": {
      "id": 1,
      "name": "John Doe",
      "email": "user@example.com",
      "roles": ["customer"],
      "permissions": ["read:catalog", "write:orders"],
      "two_factor_enabled": false
    },
    "token": "1|abc123def456ghi789jkl012mno345pqr678stu901vwx234yz",
    "token_type": "Bearer",
    "expires_at": "2025-08-18T10:30:00Z",
    "scopes": ["read:catalog", "write:orders"]
  }
}
```

### 2. API Key Authentication

For server-to-server communication:

```http
GET /api/v1/artists
Authorization: Bearer sk_live_abc123def456...
Accept: application/json
```

### 3. OAuth 2.0 (Third-Party Integration)

```http
# Step 1: Redirect to authorization
GET /oauth/authorize?client_id=123&redirect_uri=https://app.com/callback&response_type=code&scope=read:catalog

# Step 2: Exchange code for token
POST /oauth/token
Content-Type: application/json

{
  "grant_type": "authorization_code",
  "client_id": "123",
  "client_secret": "secret",
  "code": "auth_code_here",
  "redirect_uri": "https://app.com/callback"
}
```

## Token Management

### Token Types

| Type | Prefix | Usage | Expiration |
|------|--------|-------|------------|
| **Personal Access Token** | `pat_` | User authentication | 7 days (configurable) |
| **API Key** | `sk_live_` | Server-to-server | No expiration |
| **Temporary Token** | `tmp_` | Short-term access | 1 hour |
| **Refresh Token** | `ref_` | Token renewal | 30 days |

### Token Operations

#### List User Tokens
```http
GET /api/auth/tokens
Authorization: Bearer {token}
```

**Response:**
```json
{
  "data": [
    {
      "id": "1",
      "name": "iPhone 15 Pro",
      "last_used_at": "2025-07-18T10:30:00Z",
      "created_at": "2025-07-15T09:00:00Z",
      "expires_at": "2025-07-22T09:00:00Z",
      "scopes": ["read:catalog", "write:orders"],
      "is_current": true
    }
  ]
}
```

#### Refresh Token
```http
POST /api/auth/refresh
Authorization: Bearer {token}
```

#### Revoke Token
```http
DELETE /api/auth/tokens/{token_id}
Authorization: Bearer {token}
```

#### Revoke All Tokens
```http
POST /api/auth/logout-all
Authorization: Bearer {token}
```

## Multi-Factor Authentication

### Enable 2FA

```http
POST /api/auth/two-factor/enable
Authorization: Bearer {token}
```

**Response:**
```json
{
  "data": {
    "qr_code": "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjAwIi...",
    "secret_key": "JBSWY3DPEHPK3PXP",
    "recovery_codes": [
      "12345-67890",
      "abcde-fghij",
      "klmno-pqrst"
    ]
  }
}
```

### Verify 2FA Setup

```http
POST /api/auth/two-factor/confirm
Authorization: Bearer {token}
Content-Type: application/json

{
  "code": "123456"
}
```

### Login with 2FA

```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "secure_password",
  "device_name": "iPhone 15 Pro",
  "two_factor_code": "123456"
}
```

### Recovery Code Login

```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "secure_password",
  "device_name": "iPhone 15 Pro",
  "recovery_code": "12345-67890"
}
```

## Permission Scopes

### Available Scopes

| Scope | Description | Resources |
|-------|-------------|-----------|
| `read:catalog` | Read music catalog | Artists, Albums, Tracks, Genres |
| `write:catalog` | Modify music catalog | Artists, Albums, Tracks, Genres |
| `read:customers` | Read customer data | Customers, Orders |
| `write:customers` | Modify customer data | Customers, Orders |
| `read:employees` | Read employee data | Employees, Departments |
| `write:employees` | Modify employee data | Employees, Departments |
| `read:invoices` | Read invoice data | Invoices, Payments |
| `write:invoices` | Modify invoice data | Invoices, Payments |
| `read:playlists` | Read playlist data | Playlists, Tracks |
| `write:playlists` | Modify playlist data | Playlists, Tracks |
| `admin:all` | Full administrative access | All resources |

### Scope-Based Token Creation

```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "admin@example.com",
  "password": "admin_password",
  "device_name": "Admin Dashboard",
  "scopes": ["read:catalog", "write:catalog", "read:customers"]
}
```

### Check Token Scopes

```http
GET /api/auth/me
Authorization: Bearer {token}
```

**Response:**
```json
{
  "data": {
    "user": {...},
    "token": {
      "scopes": ["read:catalog", "write:catalog"],
      "expires_at": "2025-08-18T10:30:00Z"
    }
  }
}
```

## Security Best Practices

### 1. Token Security

```javascript
// ✅ Good: Store tokens securely
localStorage.setItem('auth_token', token); // For web apps
// Use secure storage for mobile apps

// ✅ Good: Include token in Authorization header
const headers = {
  'Authorization': `Bearer ${token}`,
  'Content-Type': 'application/json'
};

// ❌ Bad: Don't include token in URL
// GET /api/v1/artists?token=abc123 (DON'T DO THIS)
```

### 2. Token Rotation

```javascript
// Implement automatic token refresh
class ApiClient {
  async makeRequest(url, options = {}) {
    let response = await fetch(url, {
      ...options,
      headers: {
        'Authorization': `Bearer ${this.token}`,
        ...options.headers
      }
    });
    
    // If token expired, refresh and retry
    if (response.status === 401) {
      await this.refreshToken();
      response = await fetch(url, {
        ...options,
        headers: {
          'Authorization': `Bearer ${this.token}`,
          ...options.headers
        }
      });
    }
    
    return response;
  }
  
  async refreshToken() {
    const response = await fetch('/api/auth/refresh', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${this.token}`
      }
    });
    
    const data = await response.json();
    this.token = data.token;
    localStorage.setItem('auth_token', this.token);
  }
}
```

### 3. Rate Limiting

Authentication endpoints have special rate limits:

| Endpoint | Limit | Window |
|----------|-------|--------|
| `/api/auth/login` | 5 attempts | 15 minutes |
| `/api/auth/register` | 3 attempts | 60 minutes |
| `/api/auth/forgot-password` | 3 attempts | 60 minutes |
| `/api/auth/two-factor/*` | 5 attempts | 15 minutes |

### 4. Security Headers

All authentication responses include security headers:

```http
Strict-Transport-Security: max-age=31536000; includeSubDomains
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block
Content-Security-Policy: default-src 'self'
```

## Implementation Examples

### React/JavaScript

```javascript
import { useState, useEffect } from 'react';

const useAuth = () => {
  const [user, setUser] = useState(null);
  const [token, setToken] = useState(localStorage.getItem('auth_token'));
  
  const login = async (email, password, deviceName = 'Web Browser') => {
    const response = await fetch('/api/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password, device_name: deviceName })
    });
    
    if (response.ok) {
      const data = await response.json();
      setToken(data.data.token);
      setUser(data.data.user);
      localStorage.setItem('auth_token', data.data.token);
      return data;
    } else {
      throw new Error('Login failed');
    }
  };
  
  const logout = async () => {
    if (token) {
      await fetch('/api/auth/logout', {
        method: 'POST',
        headers: { 'Authorization': `Bearer ${token}` }
      });
    }
    
    setToken(null);
    setUser(null);
    localStorage.removeItem('auth_token');
  };
  
  useEffect(() => {
    if (token) {
      // Verify token and get user data
      fetch('/api/auth/me', {
        headers: { 'Authorization': `Bearer ${token}` }
      })
      .then(response => response.json())
      .then(data => setUser(data.data.user))
      .catch(() => logout());
    }
  }, [token]);
  
  return { user, token, login, logout };
};
```

### Laravel/PHP Client

```php
<?php

class ChinookAuthClient
{
    private string $baseUrl;
    private ?string $token = null;
    
    public function __construct(string $baseUrl)
    {
        $this->baseUrl = rtrim($baseUrl, '/');
    }
    
    public function login(string $email, string $password, string $deviceName = 'PHP Client'): array
    {
        $response = $this->makeRequest('POST', '/api/auth/login', [
            'email' => $email,
            'password' => $password,
            'device_name' => $deviceName,
        ]);
        
        $this->token = $response['data']['token'];
        
        return $response;
    }
    
    public function logout(): void
    {
        if ($this->token) {
            $this->makeRequest('POST', '/api/auth/logout');
            $this->token = null;
        }
    }
    
    public function getUser(): array
    {
        return $this->makeRequest('GET', '/api/auth/me');
    }
    
    private function makeRequest(string $method, string $endpoint, array $data = []): array
    {
        $headers = ['Content-Type: application/json'];
        
        if ($this->token) {
            $headers[] = "Authorization: Bearer {$this->token}";
        }
        
        $ch = curl_init();
        curl_setopt_array($ch, [
            CURLOPT_URL => $this->baseUrl . $endpoint,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_CUSTOMREQUEST => $method,
            CURLOPT_HTTPHEADER => $headers,
            CURLOPT_POSTFIELDS => $data ? json_encode($data) : null,
        ]);
        
        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        
        $decoded = json_decode($response, true);
        
        if ($httpCode >= 400) {
            throw new Exception($decoded['error']['message'] ?? 'API Error');
        }
        
        return $decoded;
    }
}
```

This comprehensive authentication guide provides complete implementation details for secure API access with Laravel Sanctum.
