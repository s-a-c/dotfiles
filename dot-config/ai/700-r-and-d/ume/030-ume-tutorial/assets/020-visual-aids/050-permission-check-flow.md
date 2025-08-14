# Permission Check Flow

<link rel="stylesheet" href="../css/styles.css">
<link rel="stylesheet" href="../css/ume-docs-enhancements.css">
<script src="../js/ume-docs-enhancements.js"></script>

## Overview

This visual aid illustrates the permission check flow in the UME system, showing how user permissions are verified for various actions, including the caching mechanisms used to optimize performance.

## Permission Check Sequence

The following sequence diagram shows the complete permission check process:

```mermaid
%%{init: {'theme': 'base', 'themeVariables': {'primaryColor': '#f3f4f6', 'lineColor': '#6b7280', 'textColor': '#111827', 'mainBkg': '#ffffff', 'secondaryColor': '#60a5fa', 'tertiaryColor': '#e5e7eb'}}}%%
sequenceDiagram
    participant Controller
    participant Gate
    participant Policy
    participant PermissionManager
    participant Cache
    participant Database
    
    Controller->>Gate: authorize('action', model)
    Gate->>Policy: check if policy exists
    
    alt Policy exists
        Gate->>Policy: authorize('action', user, model)
        Policy->>PermissionManager: hasPermissionTo(user, 'action', model)
    else No policy
        Gate->>PermissionManager: hasPermissionTo(user, 'action', model)
    end
    
    PermissionManager->>Cache: get(permissionCacheKey)
    
    alt Cache hit
        Cache-->>PermissionManager: cached permissions
    else Cache miss
        PermissionManager->>Database: query user permissions
        Database-->>PermissionManager: direct permissions
        PermissionManager->>Database: query user roles
        Database-->>PermissionManager: user roles
        PermissionManager->>Database: query role permissions
        Database-->>PermissionManager: role permissions
        PermissionManager->>PermissionManager: merge permissions
        PermissionManager->>Cache: store(permissionCacheKey, permissions)
        Cache-->>PermissionManager: success
    end
    
    PermissionManager->>PermissionManager: check permission in list
    
    alt Has permission
        PermissionManager-->>Policy: true
        Policy-->>Gate: true
        Gate-->>Controller: true
    else Does not have permission
        PermissionManager-->>Policy: false
        Policy-->>Gate: false
        Gate-->>Controller: AuthorizationException
    end
```

<div class="mermaid-caption">Figure 1: Permission Check Sequence</div>

## Permission Check Flow

The following flowchart illustrates the decision process for checking permissions:

```mermaid
%%{init: {'theme': 'base', 'themeVariables': {'primaryColor': '#f3f4f6', 'lineColor': '#6b7280', 'textColor': '#111827', 'mainBkg': '#ffffff', 'secondaryColor': '#60a5fa', 'tertiaryColor': '#e5e7eb'}}}%%
flowchart TD
    A[Start Permission Check] --> B{Is Super Admin?}
    B -->|Yes| C[Allow Access]
    B -->|No| D{Check Cache}
    D -->|Cache Hit| E[Get Cached Permissions]
    D -->|Cache Miss| F[Query Direct Permissions]
    F --> G[Query User Roles]
    G --> H[Query Role Permissions]
    H --> I[Merge All Permissions]
    I --> J[Store in Cache]
    J --> E
    E --> K{Has Exact Permission?}
    K -->|Yes| C
    K -->|No| L{Has Wildcard Permission?}
    L -->|Yes| C
    L -->|No| M{Team-Specific Check?}
    M -->|Yes| N{Has Team Permission?}
    M -->|No| O[Deny Access]
    N -->|Yes| C
    N -->|No| O
```

<div class="mermaid-caption">Figure 2: Permission Check Flow</div>

## Permission Caching Mechanism

The following diagram illustrates how permission caching works in the UME system:

```mermaid
%%{init: {'theme': 'base', 'themeVariables': {'primaryColor': '#f3f4f6', 'lineColor': '#6b7280', 'textColor': '#111827', 'mainBkg': '#ffffff', 'secondaryColor': '#60a5fa', 'tertiaryColor': '#e5e7eb'}}}%%
graph TD
    subgraph "Cache Layer"
        CacheStore[Cache Store]
        CacheKey[Cache Key Generation]
        CacheTags[Cache Tags]
        CacheInvalidation[Cache Invalidation]
    end
    
    subgraph "Permission Manager"
        PermissionCheck[Permission Check]
        PermissionRetrieval[Permission Retrieval]
        PermissionMerge[Permission Merge]
    end
    
    subgraph "Database Layer"
        UserPermissions[User Permissions]
        RolePermissions[Role Permissions]
        TeamPermissions[Team Permissions]
    end
    
    %% Connections
    PermissionCheck -->|1. Generate key| CacheKey
    CacheKey -->|2. Check cache| CacheStore
    CacheStore -->|3a. Cache hit| PermissionCheck
    CacheStore -->|3b. Cache miss| PermissionRetrieval
    PermissionRetrieval -->|4a. Query| UserPermissions
    PermissionRetrieval -->|4b. Query| RolePermissions
    PermissionRetrieval -->|4c. Query| TeamPermissions
    UserPermissions -->|5a. Return| PermissionMerge
    RolePermissions -->|5b. Return| PermissionMerge
    TeamPermissions -->|5c. Return| PermissionMerge
    PermissionMerge -->|6. Combine| PermissionCheck
    PermissionCheck -->|7. Store result| CacheStore
    CacheStore -->|8. Tag cache| CacheTags
    
    %% Invalidation flow
    UserPermissions -->|Changes trigger| CacheInvalidation
    RolePermissions -->|Changes trigger| CacheInvalidation
    TeamPermissions -->|Changes trigger| CacheInvalidation
    CacheInvalidation -->|Flush by tags| CacheTags
    CacheTags -->|Clear tagged| CacheStore
```

<div class="mermaid-caption">Figure 3: Permission Caching Mechanism</div>

## Permission Data Model

The following entity relationship diagram shows the database schema for permissions:

```mermaid
%%{init: {'theme': 'base', 'themeVariables': {'primaryColor': '#f3f4f6', 'lineColor': '#6b7280', 'textColor': '#111827', 'mainBkg': '#ffffff', 'secondaryColor': '#60a5fa', 'tertiaryColor': '#e5e7eb'}}}%%
erDiagram
    USERS ||--o{ MODEL_HAS_PERMISSIONS : has
    USERS ||--o{ MODEL_HAS_ROLES : has
    PERMISSIONS ||--o{ MODEL_HAS_PERMISSIONS : granted_to
    PERMISSIONS ||--o{ ROLE_HAS_PERMISSIONS : granted_to
    ROLES ||--o{ MODEL_HAS_ROLES : assigned_to
    ROLES ||--o{ ROLE_HAS_PERMISSIONS : has
    TEAMS ||--o{ MODEL_HAS_PERMISSIONS : scopes
    TEAMS ||--o{ MODEL_HAS_ROLES : scopes
    
    USERS {
        uuid id
        string name
        string email
        string type
    }
    
    PERMISSIONS {
        uuid id
        string name
        string guard_name
        timestamp created_at
        timestamp updated_at
    }
    
    ROLES {
        uuid id
        string name
        string guard_name
        timestamp created_at
        timestamp updated_at
    }
    
    TEAMS {
        uuid id
        string name
        string description
    }
    
    MODEL_HAS_PERMISSIONS {
        uuid permission_id
        string model_type
        uuid model_id
        uuid team_id
    }
    
    MODEL_HAS_ROLES {
        uuid role_id
        string model_type
        uuid model_id
        uuid team_id
    }
    
    ROLE_HAS_PERMISSIONS {
        uuid permission_id
        uuid role_id
    }
```

<div class="mermaid-caption">Figure 4: Permission Data Model</div>

## Permission Check in Different Contexts

The following diagram illustrates how permissions are checked in different contexts:

```mermaid
%%{init: {'theme': 'base', 'themeVariables': {'primaryColor': '#f3f4f6', 'lineColor': '#6b7280', 'textColor': '#111827', 'mainBkg': '#ffffff', 'secondaryColor': '#60a5fa', 'tertiaryColor': '#e5e7eb'}}}%%
graph TD
    subgraph "Controller Layer"
        C1[Web Controller]
        C2[API Controller]
        C3[Console Command]
    end
    
    subgraph "Authorization Layer"
        A1[Gate Facade]
        A2[Policies]
        A3[Middleware]
        A4[Blade Directives]
    end
    
    subgraph "Permission Layer"
        P1[Permission Manager]
        P2[Role Manager]
        P3[Team Permission Manager]
    end
    
    %% Web flow
    C1 -->|authorize()| A1
    C1 -->|@can| A4
    A4 -->|check| A1
    A1 -->|policy| A2
    A2 -->|check| P1
    
    %% API flow
    C2 -->|middleware| A3
    A3 -->|check| A1
    A1 -->|direct| P1
    
    %% Console flow
    C3 -->|direct| P1
    
    %% Permission checks
    P1 -->|check direct| P1
    P1 -->|check roles| P2
    P1 -->|check team| P3
    P2 -->|has permission| P1
    P3 -->|team context| P1
```

<div class="mermaid-caption">Figure 5: Permission Check in Different Contexts</div>

## Performance Comparison

The following chart compares the performance of cached vs. uncached permission checks:

```mermaid
%%{init: {'theme': 'base', 'themeVariables': {'primaryColor': '#f3f4f6', 'lineColor': '#6b7280', 'textColor': '#111827', 'mainBkg': '#ffffff', 'secondaryColor': '#60a5fa', 'tertiaryColor': '#e5e7eb'}}}%%
graph TD
    subgraph "Response Time (ms)"
        U1[Uncached - First Check: 120ms]
        U2[Uncached - Subsequent Checks: 100ms]
        C1[Cached - First Check: 120ms]
        C2[Cached - Subsequent Checks: 5ms]
    end
    
    subgraph "Database Queries"
        UQ1[Uncached - First Check: 5 queries]
        UQ2[Uncached - Subsequent Checks: 5 queries]
        CQ1[Cached - First Check: 5 queries]
        CQ2[Cached - Subsequent Checks: 0 queries]
    end
    
    subgraph "Memory Usage"
        UM1[Uncached - Per Request: 2MB]
        CM1[Cached - Per Request: 2.1MB]
        CM2[Cached - Cache Size: ~10KB per user]
    end
```

<div class="mermaid-caption">Figure 6: Performance Comparison of Cached vs. Uncached Permission Checks</div>

## Related Resources

- [Permission Implementation](../../050-implementation/040-phase3-teams-permissions/030-permissions.md)
- [Role Implementation](../../050-implementation/040-phase3-teams-permissions/040-roles.md)
- [Permission Caching](../../050-implementation/040-phase3-teams-permissions/050-permission-caching.md)
- [spatie/laravel-permission Documentation](https://spatie.be/docs/laravel-permission)
- [Laravel Authorization Documentation](https://laravel.com/docs/authorization)
- [Diagram Style Guide](./diagram-style-guide.md)
