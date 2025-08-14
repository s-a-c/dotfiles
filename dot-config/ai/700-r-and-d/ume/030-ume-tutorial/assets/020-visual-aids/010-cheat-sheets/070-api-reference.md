# UME API Reference

<link rel="stylesheet" href="../../css/styles.css">
<link rel="stylesheet" href="../../css/ume-docs-enhancements.css">
<script src="../../js/ume-docs-enhancements.js"></script>

## Overview

This API reference documents the endpoints available in the UME (User Model Enhancements) system. These endpoints allow you to interact with users, teams, permissions, and other UME-related features programmatically.

## Authentication

All API endpoints require authentication. The UME API supports the following authentication methods:

### Token Authentication

```http
GET /api/user
Accept: application/json
Authorization: Bearer {your-token}
```

### OAuth2 Authentication

```http
GET /api/user
Accept: application/json
Authorization: Bearer {oauth-token}
```

## Response Format

All API responses are returned in JSON format with a consistent structure:

```json
{
    "success": true,
    "data": {
        // Response data here
    },
    "message": "Operation successful",
    "errors": null
}
```

For error responses:

```json
{
    "success": false,
    "data": null,
    "message": "An error occurred",
    "errors": {
        "field": ["Error message"]
    }
}
```

## Pagination

List endpoints support pagination with the following query parameters:

- `page`: Page number (default: 1)
- `per_page`: Items per page (default: 15, max: 100)

Paginated responses include metadata:

```json
{
    "success": true,
    "data": [...],
    "meta": {
        "current_page": 1,
        "from": 1,
        "last_page": 5,
        "path": "https://example.com/api/users",
        "per_page": 15,
        "to": 15,
        "total": 75
    }
}
```

## User Endpoints

### Get Current User

```http
GET /api/user
```

Returns the currently authenticated user.

**Response:**

```json
{
    "success": true,
    "data": {
        "id": 1,
        "ulid": "01FXYZ123456789ABCDEFGHIJK",
        "name": "John Doe",
        "email": "john@example.com",
        "type": "App\\Models\\User",
        "status": "active",
        "email_verified_at": "2023-01-01T00:00:00.000000Z",
        "created_at": "2023-01-01T00:00:00.000000Z",
        "updated_at": "2023-01-01T00:00:00.000000Z"
    }
}
```

### List Users

```http
GET /api/users
```

Returns a paginated list of users.

**Query Parameters:**

- `search`: Search term for name or email
- `type`: Filter by user type
- `status`: Filter by user status
- `team_id`: Filter by team membership

**Response:**

```json
{
    "success": true,
    "data": [
        {
            "id": 1,
            "ulid": "01FXYZ123456789ABCDEFGHIJK",
            "name": "John Doe",
            "email": "john@example.com",
            "type": "App\\Models\\User",
            "status": "active"
        },
        // More users...
    ],
    "meta": {
        // Pagination metadata
    }
}
```

### Get User

```http
GET /api/users/{id}
```

Returns a specific user by ID.

**URL Parameters:**

- `id`: User ID or ULID

**Response:**

```json
{
    "success": true,
    "data": {
        "id": 1,
        "ulid": "01FXYZ123456789ABCDEFGHIJK",
        "name": "John Doe",
        "email": "john@example.com",
        "type": "App\\Models\\User",
        "status": "active",
        "email_verified_at": "2023-01-01T00:00:00.000000Z",
        "created_at": "2023-01-01T00:00:00.000000Z",
        "updated_at": "2023-01-01T00:00:00.000000Z"
    }
}
```

### Create User

```http
POST /api/users
Content-Type: application/json

{
    "name": "Jane Doe",
    "email": "jane@example.com",
    "password": "secure_password",
    "password_confirmation": "secure_password",
    "type": "App\\Models\\User"
}
```

Creates a new user.

**Request Body:**

- `name`: User's name (required)
- `email`: User's email (required, unique)
- `password`: User's password (required, min: 8 characters)
- `password_confirmation`: Password confirmation (required)
- `type`: User type class (optional, default: App\\Models\\User)

**Response:**

```json
{
    "success": true,
    "data": {
        "id": 2,
        "ulid": "01FXYZ123456789ABCDEFGHLMN",
        "name": "Jane Doe",
        "email": "jane@example.com",
        "type": "App\\Models\\User",
        "status": "pending",
        "created_at": "2023-01-02T00:00:00.000000Z",
        "updated_at": "2023-01-02T00:00:00.000000Z"
    },
    "message": "User created successfully"
}
```

### Update User

```http
PUT /api/users/{id}
Content-Type: application/json

{
    "name": "Jane Smith",
    "email": "jane.smith@example.com"
}
```

Updates an existing user.

**URL Parameters:**

- `id`: User ID or ULID

**Request Body:**

- `name`: User's name (optional)
- `email`: User's email (optional, unique)
- `password`: User's password (optional, min: 8 characters)
- `password_confirmation`: Password confirmation (required if password is provided)
- `type`: User type class (optional)

**Response:**

```json
{
    "success": true,
    "data": {
        "id": 2,
        "ulid": "01FXYZ123456789ABCDEFGHLMN",
        "name": "Jane Smith",
        "email": "jane.smith@example.com",
        "type": "App\\Models\\User",
        "status": "pending",
        "created_at": "2023-01-02T00:00:00.000000Z",
        "updated_at": "2023-01-02T00:00:00.000000Z"
    },
    "message": "User updated successfully"
}
```

### Delete User

```http
DELETE /api/users/{id}
```

Deletes a user.

**URL Parameters:**

- `id`: User ID or ULID

**Response:**

```json
{
    "success": true,
    "message": "User deleted successfully"
}
```

### Change User Status

```http
POST /api/users/{id}/status
Content-Type: application/json

{
    "status": "active"
}
```

Changes a user's status.

**URL Parameters:**

- `id`: User ID or ULID

**Request Body:**

- `status`: New status (required, one of: pending, active, suspended, locked)

**Response:**

```json
{
    "success": true,
    "data": {
        "id": 2,
        "status": "active"
    },
    "message": "User status updated successfully"
}
```

## Team Endpoints

### List Teams

```http
GET /api/teams
```

Returns a paginated list of teams.

**Query Parameters:**

- `search`: Search term for team name
- `owner_id`: Filter by owner ID
- `status`: Filter by team status

**Response:**

```json
{
    "success": true,
    "data": [
        {
            "id": 1,
            "ulid": "01FXYZ123456789ABCDEFGHIJK",
            "name": "Development Team",
            "description": "Our development team",
            "owner_id": 1,
            "status": "active",
            "created_at": "2023-01-01T00:00:00.000000Z",
            "updated_at": "2023-01-01T00:00:00.000000Z"
        },
        // More teams...
    ],
    "meta": {
        // Pagination metadata
    }
}
```

### Get Team

```http
GET /api/teams/{id}
```

Returns a specific team by ID.

**URL Parameters:**

- `id`: Team ID or ULID

**Response:**

```json
{
    "success": true,
    "data": {
        "id": 1,
        "ulid": "01FXYZ123456789ABCDEFGHIJK",
        "name": "Development Team",
        "description": "Our development team",
        "owner_id": 1,
        "status": "active",
        "created_at": "2023-01-01T00:00:00.000000Z",
        "updated_at": "2023-01-01T00:00:00.000000Z",
        "owner": {
            "id": 1,
            "name": "John Doe",
            "email": "john@example.com"
        }
    }
}
```

### Create Team

```http
POST /api/teams
Content-Type: application/json

{
    "name": "Marketing Team",
    "description": "Our marketing team",
    "owner_id": 1
}
```

Creates a new team.

**Request Body:**

- `name`: Team name (required)
- `description`: Team description (optional)
- `owner_id`: Owner's user ID (optional, defaults to authenticated user)

**Response:**

```json
{
    "success": true,
    "data": {
        "id": 2,
        "ulid": "01FXYZ123456789ABCDEFGHLMN",
        "name": "Marketing Team",
        "description": "Our marketing team",
        "owner_id": 1,
        "status": "active",
        "created_at": "2023-01-02T00:00:00.000000Z",
        "updated_at": "2023-01-02T00:00:00.000000Z"
    },
    "message": "Team created successfully"
}
```

### Update Team

```http
PUT /api/teams/{id}
Content-Type: application/json

{
    "name": "Marketing Department",
    "description": "Our marketing department"
}
```

Updates an existing team.

**URL Parameters:**

- `id`: Team ID or ULID

**Request Body:**

- `name`: Team name (optional)
- `description`: Team description (optional)
- `owner_id`: Owner's user ID (optional)

**Response:**

```json
{
    "success": true,
    "data": {
        "id": 2,
        "ulid": "01FXYZ123456789ABCDEFGHLMN",
        "name": "Marketing Department",
        "description": "Our marketing department",
        "owner_id": 1,
        "status": "active",
        "created_at": "2023-01-02T00:00:00.000000Z",
        "updated_at": "2023-01-02T00:00:00.000000Z"
    },
    "message": "Team updated successfully"
}
```

### Delete Team

```http
DELETE /api/teams/{id}
```

Deletes a team.

**URL Parameters:**

- `id`: Team ID or ULID

**Response:**

```json
{
    "success": true,
    "message": "Team deleted successfully"
}
```

### List Team Members

```http
GET /api/teams/{id}/members
```

Returns a paginated list of team members.

**URL Parameters:**

- `id`: Team ID or ULID

**Response:**

```json
{
    "success": true,
    "data": [
        {
            "id": 1,
            "name": "John Doe",
            "email": "john@example.com",
            "role": "owner",
            "joined_at": "2023-01-01T00:00:00.000000Z"
        },
        // More members...
    ],
    "meta": {
        // Pagination metadata
    }
}
```

### Add Team Member

```http
POST /api/teams/{id}/members
Content-Type: application/json

{
    "user_id": 2,
    "role": "member"
}
```

Adds a member to a team.

**URL Parameters:**

- `id`: Team ID or ULID

**Request Body:**

- `user_id`: User ID (required)
- `role`: Role in the team (required, one of: owner, admin, member)

**Response:**

```json
{
    "success": true,
    "data": {
        "user_id": 2,
        "team_id": 1,
        "role": "member"
    },
    "message": "Member added successfully"
}
```

### Update Team Member

```http
PUT /api/teams/{id}/members/{user_id}
Content-Type: application/json

{
    "role": "admin"
}
```

Updates a team member's role.

**URL Parameters:**

- `id`: Team ID or ULID
- `user_id`: User ID

**Request Body:**

- `role`: New role (required, one of: owner, admin, member)

**Response:**

```json
{
    "success": true,
    "data": {
        "user_id": 2,
        "team_id": 1,
        "role": "admin"
    },
    "message": "Member updated successfully"
}
```

### Remove Team Member

```http
DELETE /api/teams/{id}/members/{user_id}
```

Removes a member from a team.

**URL Parameters:**

- `id`: Team ID or ULID
- `user_id`: User ID

**Response:**

```json
{
    "success": true,
    "message": "Member removed successfully"
}
```

## Permission Endpoints

### List Permissions

```http
GET /api/permissions
```

Returns a paginated list of permissions.

**Query Parameters:**

- `search`: Search term for permission name
- `guard`: Filter by guard name

**Response:**

```json
{
    "success": true,
    "data": [
        {
            "id": 1,
            "name": "edit-posts",
            "guard_name": "web",
            "created_at": "2023-01-01T00:00:00.000000Z",
            "updated_at": "2023-01-01T00:00:00.000000Z"
        },
        // More permissions...
    ],
    "meta": {
        // Pagination metadata
    }
}
```

### Create Permission

```http
POST /api/permissions
Content-Type: application/json

{
    "name": "delete-posts",
    "guard_name": "web"
}
```

Creates a new permission.

**Request Body:**

- `name`: Permission name (required)
- `guard_name`: Guard name (optional, default: web)

**Response:**

```json
{
    "success": true,
    "data": {
        "id": 2,
        "name": "delete-posts",
        "guard_name": "web",
        "created_at": "2023-01-02T00:00:00.000000Z",
        "updated_at": "2023-01-02T00:00:00.000000Z"
    },
    "message": "Permission created successfully"
}
```

### List Roles

```http
GET /api/roles
```

Returns a paginated list of roles.

**Query Parameters:**

- `search`: Search term for role name
- `guard`: Filter by guard name

**Response:**

```json
{
    "success": true,
    "data": [
        {
            "id": 1,
            "name": "editor",
            "guard_name": "web",
            "created_at": "2023-01-01T00:00:00.000000Z",
            "updated_at": "2023-01-01T00:00:00.000000Z",
            "permissions": [
                {
                    "id": 1,
                    "name": "edit-posts",
                    "guard_name": "web"
                }
            ]
        },
        // More roles...
    ],
    "meta": {
        // Pagination metadata
    }
}
```

### Create Role

```http
POST /api/roles
Content-Type: application/json

{
    "name": "moderator",
    "guard_name": "web",
    "permissions": [1, 2]
}
```

Creates a new role.

**Request Body:**

- `name`: Role name (required)
- `guard_name`: Guard name (optional, default: web)
- `permissions`: Array of permission IDs (optional)

**Response:**

```json
{
    "success": true,
    "data": {
        "id": 2,
        "name": "moderator",
        "guard_name": "web",
        "created_at": "2023-01-02T00:00:00.000000Z",
        "updated_at": "2023-01-02T00:00:00.000000Z",
        "permissions": [
            {
                "id": 1,
                "name": "edit-posts",
                "guard_name": "web"
            },
            {
                "id": 2,
                "name": "delete-posts",
                "guard_name": "web"
            }
        ]
    },
    "message": "Role created successfully"
}
```

### Assign Role to User

```http
POST /api/users/{id}/roles
Content-Type: application/json

{
    "role": "editor",
    "team_id": 1
}
```

Assigns a role to a user.

**URL Parameters:**

- `id`: User ID or ULID

**Request Body:**

- `role`: Role name (required)
- `team_id`: Team ID (optional, for team roles)

**Response:**

```json
{
    "success": true,
    "message": "Role assigned successfully"
}
```

### Remove Role from User

```http
DELETE /api/users/{id}/roles/{role}
```

Removes a role from a user.

**URL Parameters:**

- `id`: User ID or ULID
- `role`: Role name

**Query Parameters:**

- `team_id`: Team ID (optional, for team roles)

**Response:**

```json
{
    "success": true,
    "message": "Role removed successfully"
}
```

## State Machine Endpoints

### Get User Status

```http
GET /api/users/{id}/status
```

Returns a user's current status.

**URL Parameters:**

- `id`: User ID or ULID

**Response:**

```json
{
    "success": true,
    "data": {
        "status": "active",
        "label": "Active",
        "color": "green",
        "available_transitions": [
            {
                "to": "suspended",
                "label": "Suspend"
            }
        ]
    }
}
```

### Transition User Status

```http
POST /api/users/{id}/status/transition
Content-Type: application/json

{
    "to": "suspended",
    "reason": "Violation of terms"
}
```

Transitions a user's status.

**URL Parameters:**

- `id`: User ID or ULID

**Request Body:**

- `to`: Target state (required)
- `reason`: Reason for transition (optional)

**Response:**

```json
{
    "success": true,
    "data": {
        "status": "suspended",
        "label": "Suspended",
        "color": "red",
        "available_transitions": [
            {
                "to": "active",
                "label": "Reactivate"
            }
        ]
    },
    "message": "Status transitioned successfully"
}
```

### Get User Status History

```http
GET /api/users/{id}/status/history
```

Returns a user's status history.

**URL Parameters:**

- `id`: User ID or ULID

**Response:**

```json
{
    "success": true,
    "data": [
        {
            "from": "pending",
            "to": "active",
            "created_at": "2023-01-01T12:00:00.000000Z",
            "created_by": {
                "id": 1,
                "name": "John Doe"
            }
        },
        {
            "from": "active",
            "to": "suspended",
            "created_at": "2023-01-02T12:00:00.000000Z",
            "created_by": {
                "id": 1,
                "name": "John Doe"
            },
            "reason": "Violation of terms"
        }
    ]
}
```

## Real-time Endpoints

### Get User Presence

```http
GET /api/users/{id}/presence
```

Returns a user's presence status.

**URL Parameters:**

- `id`: User ID or ULID

**Response:**

```json
{
    "success": true,
    "data": {
        "online": true,
        "last_active": "2023-01-02T12:00:00.000000Z"
    }
}
```

### Get Team Presence

```http
GET /api/teams/{id}/presence
```

Returns presence status for all team members.

**URL Parameters:**

- `id`: Team ID or ULID

**Response:**

```json
{
    "success": true,
    "data": [
        {
            "user_id": 1,
            "name": "John Doe",
            "online": true,
            "last_active": "2023-01-02T12:00:00.000000Z"
        },
        {
            "user_id": 2,
            "name": "Jane Smith",
            "online": false,
            "last_active": "2023-01-01T12:00:00.000000Z"
        }
    ]
}
```

## Error Codes

| Code | Description |
|------|-------------|
| 400 | Bad Request - The request was malformed |
| 401 | Unauthorized - Authentication is required |
| 403 | Forbidden - You don't have permission to access this resource |
| 404 | Not Found - The requested resource was not found |
| 422 | Unprocessable Entity - Validation errors |
| 429 | Too Many Requests - Rate limit exceeded |
| 500 | Internal Server Error - Something went wrong on the server |

## Rate Limiting

API requests are rate-limited to prevent abuse. The default limits are:

- 60 requests per minute for authenticated users
- 10 requests per minute for unauthenticated users

Rate limit information is included in the response headers:

```
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 59
X-RateLimit-Reset: 1609459200
```

## Versioning

The API is versioned using URL path versioning. The current version is v1:

```
https://example.com/api/v1/users
```

## Related Resources

- [Quick Start Guide](../../../090-quick-start/000-index.md)
- [Common Patterns and Snippets](050-common-patterns-snippets.md)
- [UME Implementation Guide](../../../050-implementation/000-index.md)
