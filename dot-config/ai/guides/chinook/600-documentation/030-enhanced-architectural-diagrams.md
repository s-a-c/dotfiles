# Enhanced Architectural Diagrams

**Version:** 1.0  
**Created:** 2025-07-16  
**Last Updated:** 2025-07-16  
**Scope:** Comprehensive architectural visualization for Chinook project

## Table of Contents

1. [Overview](#1-overview)
2. [System Architecture](#2-system-architecture)
3. [Database Architecture](#3-database-architecture)
4. [Application Layer Architecture](#4-application-layer-architecture)
5. [Security Architecture](#5-security-architecture)
6. [Deployment Architecture](#6-deployment-architecture)

## 1. Overview

This document provides enhanced architectural diagrams for the Chinook project, offering comprehensive visual documentation that supports educational objectives and system understanding.

### 1.1 Diagram Standards

All diagrams follow the established visual documentation standards:
- **WCAG 2.1 AA compliant** color schemes and contrast ratios
- **Accessible markup** with proper alt text and descriptions
- **Educational focus** with clear labels and explanations
- **Consistent styling** across all architectural views

## 2. System Architecture

### 2.1 High-Level System Overview

```mermaid
---
title: Chinook System Architecture Overview
---
graph TB
    subgraph "External Users"
        U1[Students/Developers]
        U2[Administrators]
        U3[Content Managers]
    end
    
    subgraph "Presentation Layer"
        P1[Filament Admin Panel]
        P2[Livewire Components]
        P3[Blade Templates]
        P4[API Endpoints]
    end
    
    subgraph "Application Layer"
        A1[Laravel Controllers]
        A2[Filament Resources]
        A3[Middleware Stack]
        A4[Service Providers]
        A5[Event Listeners]
    end
    
    subgraph "Business Logic Layer"
        B1[Eloquent Models]
        B2[Service Classes]
        B3[Repository Pattern]
        B4[Domain Events]
        B5[Business Rules]
    end
    
    subgraph "Data Access Layer"
        D1[Database Abstraction]
        D2[Query Builder]
        D3[Migration System]
        D4[Seeder System]
    end
    
    subgraph "Infrastructure Layer"
        I1[SQLite Database]
        I2[File System]
        I3[Cache Layer]
        I4[Queue System]
        I5[Logging System]
    end
    
    subgraph "External Packages"
        E1[aliziodev/laravel-taxonomy]
        E2[filament/filament]
        E3[spatie/laravel-permission]
        E4[spatie/laravel-medialibrary]
    end
    
    %% User interactions
    U1 --> P1
    U2 --> P1
    U3 --> P1
    
    %% Presentation to Application
    P1 --> A2
    P2 --> A1
    P3 --> A1
    P4 --> A1
    
    %% Application to Business Logic
    A1 --> B1
    A2 --> B1
    A3 --> B5
    A4 --> B2
    A5 --> B4
    
    %% Business Logic to Data Access
    B1 --> D1
    B2 --> D2
    B3 --> D1
    
    %% Data Access to Infrastructure
    D1 --> I1
    D2 --> I1
    D3 --> I1
    D4 --> I1
    
    %% Infrastructure connections
    B2 --> I3
    B4 --> I4
    A5 --> I5
    
    %% External package integration
    B1 --> E1
    A2 --> E2
    B5 --> E3
    B1 --> E4
    
    %% Styling
    classDef userLayer fill:#e3f2fd,stroke:#1976d2,stroke-width:2px
    classDef presentationLayer fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px
    classDef applicationLayer fill:#e8f5e8,stroke:#388e3c,stroke-width:2px
    classDef businessLayer fill:#fff3e0,stroke:#f57c00,stroke-width:2px
    classDef dataLayer fill:#fce4ec,stroke:#c2185b,stroke-width:2px
    classDef infraLayer fill:#f1f8e9,stroke:#689f38,stroke-width:2px
    classDef externalLayer fill:#e0f2f1,stroke:#00796b,stroke-width:2px
    
    class U1,U2,U3 userLayer
    class P1,P2,P3,P4 presentationLayer
    class A1,A2,A3,A4,A5 applicationLayer
    class B1,B2,B3,B4,B5 businessLayer
    class D1,D2,D3,D4 dataLayer
    class I1,I2,I3,I4,I5 infraLayer
    class E1,E2,E3,E4 externalLayer
```

### 2.2 Component Interaction Flow

```mermaid
---
title: Request Processing Flow
---
sequenceDiagram
    participant User as User/Admin
    participant Panel as Filament Panel
    participant Resource as Filament Resource
    participant Model as Eloquent Model
    participant Taxonomy as Taxonomy Service
    participant DB as SQLite Database
    participant Cache as Cache Layer
    
    User->>Panel: Access Artist Management
    Panel->>Resource: Load ArtistResource
    Resource->>Model: Query Artist::with('taxonomies')
    
    alt Cache Hit
        Model->>Cache: Check cached data
        Cache-->>Model: Return cached results
    else Cache Miss
        Model->>DB: Execute database query
        DB-->>Model: Return raw data
        Model->>Cache: Store results in cache
    end
    
    Model->>Taxonomy: Load taxonomy relationships
    Taxonomy->>DB: Query taxonomy data
    DB-->>Taxonomy: Return taxonomy results
    Taxonomy-->>Model: Return enriched data
    
    Model-->>Resource: Return formatted data
    Resource-->>Panel: Render table/form
    Panel-->>User: Display interface
    
    Note over User,Cache: All operations include proper error handling and logging
```

## 3. Database Architecture

### 3.1 Entity Relationship Overview

```mermaid
---
title: Chinook Database Entity Relationships
---
erDiagram
    ARTISTS {
        bigint id PK
        string name
        string public_id UK
        string slug UK
        text bio
        string website
        json social_links
        string country
        int formed_year
        boolean is_active
        timestamp created_at
        timestamp updated_at
        timestamp deleted_at
    }
    
    ALBUMS {
        bigint id PK
        bigint artist_id FK
        string title
        string public_id UK
        string slug UK
        int release_year
        text description
        string cover_image
        boolean is_active
        timestamp created_at
        timestamp updated_at
        timestamp deleted_at
    }
    
    TRACKS {
        bigint id PK
        bigint album_id FK
        bigint genre_id FK
        bigint media_type_id FK
        string name
        string public_id UK
        string slug UK
        int duration_ms
        decimal unit_price
        text lyrics
        boolean is_active
        timestamp created_at
        timestamp updated_at
        timestamp deleted_at
    }
    
    GENRES {
        bigint id PK
        string name
        string public_id UK
        string slug UK
        text description
        boolean is_active
        timestamp created_at
        timestamp updated_at
        timestamp deleted_at
    }
    
    TAXONOMIES {
        bigint id PK
        string name
        string slug UK
        string type
        text description
        bigint parent_id FK
        int sort_order
        boolean is_active
        timestamp created_at
        timestamp updated_at
    }
    
    TAXABLES {
        bigint id PK
        bigint taxonomy_id FK
        string taxable_type
        bigint taxable_id
        timestamp created_at
        timestamp updated_at
    }
    
    CUSTOMERS {
        bigint id PK
        string first_name
        string last_name
        string email UK
        string phone
        text address
        string city
        string state
        string country
        string postal_code
        bigint support_rep_id FK
        timestamp created_at
        timestamp updated_at
        timestamp deleted_at
    }
    
    INVOICES {
        bigint id PK
        bigint customer_id FK
        string invoice_number UK
        date invoice_date
        text billing_address
        string billing_city
        string billing_state
        string billing_country
        string billing_postal_code
        decimal total
        timestamp created_at
        timestamp updated_at
    }
    
    INVOICE_LINES {
        bigint id PK
        bigint invoice_id FK
        bigint track_id FK
        decimal unit_price
        int quantity
        decimal line_total
        timestamp created_at
        timestamp updated_at
    }
    
    EMPLOYEES {
        bigint id PK
        string first_name
        string last_name
        string title
        bigint reports_to FK
        date birth_date
        date hire_date
        text address
        string city
        string state
        string country
        string postal_code
        string phone
        string fax
        string email UK
        timestamp created_at
        timestamp updated_at
        timestamp deleted_at
    }
    
    %% Relationships
    ARTISTS ||--o{ ALBUMS : "has many"
    ALBUMS ||--o{ TRACKS : "contains"
    GENRES ||--o{ TRACKS : "categorizes"
    CUSTOMERS ||--o{ INVOICES : "places"
    INVOICES ||--o{ INVOICE_LINES : "contains"
    TRACKS ||--o{ INVOICE_LINES : "sold in"
    EMPLOYEES ||--o{ CUSTOMERS : "supports"
    EMPLOYEES ||--o{ EMPLOYEES : "reports to"
    
    %% Taxonomy relationships (polymorphic)
    TAXONOMIES ||--o{ TAXABLES : "applied to"
    TAXABLES }o--|| ARTISTS : "categorizes"
    TAXABLES }o--|| ALBUMS : "categorizes"
    TAXABLES }o--|| TRACKS : "categorizes"
    TAXONOMIES ||--o{ TAXONOMIES : "parent/child"
```

## 4. Application Layer Architecture

### 4.1 Filament Resource Architecture

```mermaid
---
title: Filament Resource Component Architecture
---
graph TB
    subgraph "Resource Layer"
        R1[ArtistResource]
        R2[AlbumResource]
        R3[TrackResource]
        R4[TaxonomyResource]
    end

    subgraph "Page Components"
        P1[ListPage]
        P2[CreatePage]
        P3[EditPage]
        P4[ViewPage]
    end

    subgraph "Form Components"
        F1[TextInput]
        F2[Textarea]
        F3[Select]
        F4[FileUpload]
        F5[Repeater]
        F6[TaxonomySelect]
    end

    subgraph "Table Components"
        T1[TextColumn]
        T2[ImageColumn]
        T3[BadgeColumn]
        T4[SelectColumn]
        T5[TaxonomyColumn]
    end

    subgraph "Action Components"
        A1[CreateAction]
        A2[EditAction]
        A3[DeleteAction]
        A4[BulkAction]
        A5[TaxonomyAction]
    end

    subgraph "Model Layer"
        M1[Artist Model]
        M2[Album Model]
        M3[Track Model]
        M4[Taxonomy Model]
    end

    %% Resource to Page connections
    R1 --> P1
    R1 --> P2
    R1 --> P3
    R1 --> P4

    %% Page to Component connections
    P2 --> F1
    P2 --> F2
    P2 --> F6
    P3 --> F1
    P3 --> F2
    P3 --> F6

    P1 --> T1
    P1 --> T3
    P1 --> T5

    P1 --> A1
    P1 --> A2
    P1 --> A3
    P1 --> A4

    %% Component to Model connections
    F6 --> M4
    T5 --> M4
    A5 --> M4

    R1 --> M1
    R2 --> M2
    R3 --> M3
    R4 --> M4

    %% Styling
    classDef resourceLayer fill:#e3f2fd,stroke:#1976d2,stroke-width:2px
    classDef pageLayer fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px
    classDef componentLayer fill:#e8f5e8,stroke:#388e3c,stroke-width:2px
    classDef modelLayer fill:#fff3e0,stroke:#f57c00,stroke-width:2px

    class R1,R2,R3,R4 resourceLayer
    class P1,P2,P3,P4 pageLayer
    class F1,F2,F3,F4,F5,F6,T1,T2,T3,T4,T5,A1,A2,A3,A4,A5 componentLayer
    class M1,M2,M3,M4 modelLayer
```

### 4.2 Service Layer Architecture

```mermaid
---
title: Service Layer and Business Logic Architecture
---
graph TB
    subgraph "Controller Layer"
        C1[ArtistController]
        C2[AlbumController]
        C3[TaxonomyController]
        C4[APIController]
    end

    subgraph "Service Layer"
        S1[ArtistService]
        S2[AlbumService]
        S3[TaxonomyService]
        S4[MediaService]
        S5[CacheService]
        S6[SearchService]
    end

    subgraph "Repository Layer"
        RE1[ArtistRepository]
        RE2[AlbumRepository]
        RE3[TaxonomyRepository]
        RE4[BaseRepository]
    end

    subgraph "Event System"
        E1[ArtistCreated]
        E2[AlbumUpdated]
        E3[TaxonomyAssigned]
        E4[MediaUploaded]
    end

    subgraph "Listener System"
        L1[UpdateSearchIndex]
        L2[ClearCache]
        L3[SendNotification]
        L4[LogActivity]
    end

    subgraph "Job System"
        J1[ProcessMediaJob]
        J2[UpdateCacheJob]
        J3[SendEmailJob]
        J4[GenerateReportJob]
    end

    %% Controller to Service connections
    C1 --> S1
    C2 --> S2
    C3 --> S3
    C4 --> S1
    C4 --> S2

    %% Service to Repository connections
    S1 --> RE1
    S2 --> RE2
    S3 --> RE3
    S4 --> RE4

    %% Service interactions
    S1 --> S5
    S2 --> S5
    S1 --> S6
    S2 --> S6

    %% Event dispatching
    S1 --> E1
    S2 --> E2
    S3 --> E3
    S4 --> E4

    %% Event to Listener connections
    E1 --> L1
    E1 --> L2
    E2 --> L1
    E2 --> L2
    E3 --> L3
    E4 --> L4

    %% Listener to Job connections
    L1 --> J2
    L3 --> J3
    L4 --> J4
    S4 --> J1

    %% Styling
    classDef controllerLayer fill:#e3f2fd,stroke:#1976d2,stroke-width:2px
    classDef serviceLayer fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px
    classDef repositoryLayer fill:#e8f5e8,stroke:#388e3c,stroke-width:2px
    classDef eventLayer fill:#fff3e0,stroke:#f57c00,stroke-width:2px
    classDef listenerLayer fill:#fce4ec,stroke:#c2185b,stroke-width:2px
    classDef jobLayer fill:#f1f8e9,stroke:#689f38,stroke-width:2px

    class C1,C2,C3,C4 controllerLayer
    class S1,S2,S3,S4,S5,S6 serviceLayer
    class RE1,RE2,RE3,RE4 repositoryLayer
    class E1,E2,E3,E4 eventLayer
    class L1,L2,L3,L4 listenerLayer
    class J1,J2,J3,J4 jobLayer
```

## 5. Security Architecture

### 5.1 Authentication and Authorization Flow

```mermaid
---
title: Security Architecture and Access Control
---
graph TB
    subgraph "Authentication Layer"
        A1[Login Form]
        A2[Session Management]
        A3[Password Hashing]
        A4[Remember Token]
    end

    subgraph "Authorization Layer"
        AU1[Role-Based Access Control]
        AU2[Permission System]
        AU3[Policy Classes]
        AU4[Gate Definitions]
    end

    subgraph "Middleware Stack"
        M1[Authentication Middleware]
        M2[Authorization Middleware]
        M3[CSRF Protection]
        M4[Rate Limiting]
        M5[Input Sanitization]
    end

    subgraph "User Management"
        U1[User Model]
        U2[Role Model]
        U3[Permission Model]
        U4[User Roles Pivot]
    end

    subgraph "Protected Resources"
        PR1[Artist Management]
        PR2[Album Management]
        PR3[Taxonomy Management]
        PR4[System Settings]
    end

    %% Authentication flow
    A1 --> A2
    A2 --> A3
    A2 --> A4

    %% Authorization connections
    AU1 --> AU2
    AU2 --> AU3
    AU3 --> AU4

    %% Middleware protection
    M1 --> M2
    M2 --> M3
    M3 --> M4
    M4 --> M5

    %% User system relationships
    U1 --> U4
    U2 --> U4
    U2 --> U3

    %% Access control to resources
    AU1 --> PR1
    AU1 --> PR2
    AU1 --> PR3
    AU1 --> PR4

    %% Middleware protecting resources
    M2 --> PR1
    M2 --> PR2
    M2 --> PR3
    M2 --> PR4

    %% Authentication to authorization
    A2 --> AU1

    %% User model to authorization
    U1 --> AU1

    %% Styling
    classDef authLayer fill:#e3f2fd,stroke:#1976d2,stroke-width:2px
    classDef authzLayer fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px
    classDef middlewareLayer fill:#e8f5e8,stroke:#388e3c,stroke-width:2px
    classDef userLayer fill:#fff3e0,stroke:#f57c00,stroke-width:2px
    classDef resourceLayer fill:#fce4ec,stroke:#c2185b,stroke-width:2px

    class A1,A2,A3,A4 authLayer
    class AU1,AU2,AU3,AU4 authzLayer
    class M1,M2,M3,M4,M5 middlewareLayer
    class U1,U2,U3,U4 userLayer
    class PR1,PR2,PR3,PR4 resourceLayer
```

## 6. Deployment Architecture

### 6.1 Educational Deployment Model

```mermaid
---
title: Educational Deployment Architecture
---
graph TB
    subgraph "Development Environment"
        D1[Local Development]
        D2[Laravel Herd/Valet]
        D3[SQLite Database]
        D4[File-based Cache]
    end

    subgraph "Educational Hosting"
        E1[Shared Hosting]
        E2[VPS/Cloud Instance]
        E3[Docker Container]
        E4[GitHub Codespaces]
    end

    subgraph "Application Components"
        AC1[Laravel Application]
        AC2[Filament Admin Panel]
        AC3[Static Assets]
        AC4[User Uploads]
    end

    subgraph "Data Storage"
        DS1[SQLite Database File]
        DS2[Log Files]
        DS3[Cache Files]
        DS4[Session Files]
    end

    subgraph "External Services"
        ES1[GitHub Repository]
        ES2[Composer Packages]
        ES3[NPM Packages]
        ES4[CDN Resources]
    end

    %% Development connections
    D1 --> AC1
    D2 --> AC1
    D3 --> DS1
    D4 --> DS3

    %% Educational hosting options
    E1 --> AC1
    E2 --> AC1
    E3 --> AC1
    E4 --> AC1

    %% Application to data
    AC1 --> DS1
    AC1 --> DS2
    AC2 --> DS1
    AC3 --> DS4

    %% External dependencies
    AC1 --> ES2
    AC3 --> ES3
    AC3 --> ES4
    D1 --> ES1

    %% Styling
    classDef devLayer fill:#e3f2fd,stroke:#1976d2,stroke-width:2px
    classDef hostingLayer fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px
    classDef appLayer fill:#e8f5e8,stroke:#388e3c,stroke-width:2px
    classDef dataLayer fill:#fff3e0,stroke:#f57c00,stroke-width:2px
    classDef externalLayer fill:#fce4ec,stroke:#c2185b,stroke-width:2px

    class D1,D2,D3,D4 devLayer
    class E1,E2,E3,E4 hostingLayer
    class AC1,AC2,AC3,AC4 appLayer
    class DS1,DS2,DS3,DS4 dataLayer
    class ES1,ES2,ES3,ES4 externalLayer
```

---

## Navigation

- **Previous:** [Visual Documentation Standards](./500-visual-documentation-standards.md)
- **Next:** [Performance Benchmarking Data](./700-performance-benchmarking-data.md)
- **Index:** [Chinook Documentation Index](./000-chinook-index.md)

## Related Documentation

- [Database Configuration Guide](./000-database-configuration-guide.md)
- [Filament Panel Architecture](./filament/diagrams/060-filament-panel-architecture.md)

---

**Last Updated:** 2025-07-16  
**Maintainer:** Technical Documentation Team  
**Source:** [GitHub Repository](https://github.com/s-a-c/chinook)
