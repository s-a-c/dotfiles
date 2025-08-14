# Database Schema Diagrams and Entity Relationships

**Report Date:** 2025-07-19  
**Project:** Chinook SQLite Architecture Evaluation  
**Focus:** Visual representation of current and proposed database architectures

## 1. Current Single-Database Architecture

### 1.1. Current Schema Overview

```mermaid
erDiagram
    users ||--o{ activity_log : creates
    users ||--o{ comments : writes
    users ||--o{ chinook_customers : "may_be"
    
    chinook_artists ||--o{ chinook_albums : creates
    chinook_albums ||--o{ chinook_tracks : contains
    chinook_tracks }o--|| chinook_media_types : "has_format"
    chinook_tracks }o--|| chinook_genres : "belongs_to"
    chinook_tracks }o--o{ chinook_taxonomies : "categorized_by"
    
    chinook_employees ||--o{ chinook_customers : supports
    chinook_customers ||--o{ chinook_invoices : places
    chinook_invoices ||--o{ chinook_invoice_lines : contains
    chinook_invoice_lines }o--|| chinook_tracks : purchases
    
    chinook_playlists }o--o{ chinook_tracks : includes
    
    users {
        bigint id PK
        string name
        string email UK
        timestamp created_at
        timestamp updated_at
    }
    
    chinook_artists {
        bigint id PK
        string name
        text biography
        string public_id UK
        string slug UK
        timestamp created_at
        timestamp updated_at
    }
    
    chinook_albums {
        bigint id PK
        string title
        bigint artist_id FK
        date release_date
        string public_id UK
        string slug UK
        timestamp created_at
        timestamp updated_at
    }
    
    chinook_tracks {
        bigint id PK
        string name
        bigint album_id FK
        bigint media_type_id FK
        bigint genre_id FK
        integer milliseconds
        integer bytes
        decimal unit_price
        string public_id UK
        string slug UK
        timestamp created_at
        timestamp updated_at
    }
```

### 1.2. Current Performance Characteristics

**Database File Structure:**
```
database/
├── database.sqlite (50MB)
├── database.sqlite-wal (variable)
└── database.sqlite-shm (32KB)
```

**Connection Configuration:**
```yaml
Single Connection Pool:
  - Max Connections: 1 (SQLite limitation)
  - WAL Mode: Enabled
  - Cache Size: 64MB
  - Memory Mapping: 256MB
  - Concurrent Readers: Unlimited
  - Concurrent Writers: 1
```

## 2. Proposed Three-Database Architecture

### 2.1. Database Separation Strategy

```mermaid
graph TB
    subgraph "Main Application Database"
        A[users]
        B[sessions]
        C[cache]
        D[jobs]
        E[activity_log]
        F[comments]
        G[deleted_models]
    end
    
    subgraph "In-Memory Cache Database"
        H[temp_calculations]
        I[session_data]
        J[query_cache]
        K[computed_results]
    end
    
    subgraph "Chinook Database"
        L[chinook_artists]
        M[chinook_albums]
        N[chinook_tracks]
        O[chinook_customers]
        P[chinook_invoices]
        Q[chinook_taxonomies]
        R[tracks_fts]
        S[track_vectors]
    end
    
    A -.->|references| O
    E -.->|logs| L
    E -.->|logs| M
    E -.->|logs| N
    
    style A fill:#e1f5fe
    style H fill:#fff3e0
    style L fill:#f3e5f5
```

### 2.2. Proposed Schema Relationships

```mermaid
erDiagram
    %% Main Database
    users ||--o{ activity_log : creates
    users ||--o{ comments : writes
    users ||--o{ sessions : has
    
    %% Chinook Database (Isolated)
    chinook_artists ||--o{ chinook_albums : creates
    chinook_albums ||--o{ chinook_tracks : contains
    chinook_tracks }o--|| chinook_media_types : "has_format"
    chinook_tracks }o--o{ chinook_taxonomies : "categorized_by"
    chinook_tracks ||--|| tracks_fts : "indexed_by"
    chinook_tracks ||--o| track_vectors : "embedded_as"
    
    chinook_employees ||--o{ chinook_customers : supports
    chinook_customers ||--o{ chinook_invoices : places
    chinook_invoices ||--o{ chinook_invoice_lines : contains
    chinook_invoice_lines }o--|| chinook_tracks : purchases
    
    %% Cross-Database References (Application Level)
    users }o..o{ chinook_customers : "may_reference"
    activity_log }o..o{ chinook_tracks : "may_log"
```

### 2.3. Connection Pool Architecture

```mermaid
graph LR
    subgraph "Laravel Application"
        A[Request] --> B[Router]
        B --> C[Controller]
        C --> D[Service Layer]
    end
    
    subgraph "Database Connections"
        E[Main Connection Pool]
        F[Cache Connection Pool]
        G[Chinook Connection Pool]
    end
    
    subgraph "SQLite Databases"
        H[(database.sqlite)]
        I[(cache.sqlite :memory:)]
        J[(chinook.sqlite)]
    end
    
    D --> E
    D --> F
    D --> G
    
    E --> H
    F --> I
    G --> J
    
    style E fill:#e1f5fe
    style F fill:#fff3e0
    style G fill:#f3e5f5
```

## 3. Data Flow Analysis

### 3.1. Current Data Flow (Single Database)

```mermaid
sequenceDiagram
    participant U as User
    participant A as Application
    participant D as Database
    
    U->>A: Search Request
    A->>D: Single Query
    D-->>A: Results
    A-->>U: Response
    
    Note over A,D: Single connection<br/>Simple transaction<br/>ACID compliance
```

### 3.2. Proposed Data Flow (Three Databases)

```mermaid
sequenceDiagram
    participant U as User
    participant A as Application
    participant M as Main DB
    participant C as Cache DB
    participant Ch as Chinook DB
    
    U->>A: Complex Search Request
    A->>C: Check Cache
    C-->>A: Cache Miss
    A->>Ch: Search Tracks
    Ch-->>A: Track Results
    A->>M: Get User Preferences
    M-->>A: User Data
    A->>A: Combine Results
    A->>C: Store in Cache
    A-->>U: Response
    
    Note over A,Ch: Multiple connections<br/>Application-level joins<br/>Eventual consistency
```

## 4. Performance Impact Analysis

### 4.1. Query Performance Comparison

```mermaid
graph TB
    subgraph "Single Database Queries"
        A[Simple SELECT: 2-5ms]
        B[Complex JOIN: 10-25ms]
        C[FTS Search: 5-15ms]
        D[INSERT/UPDATE: 3-8ms]
    end
    
    subgraph "Three Database Queries"
        E[Single DB SELECT: 2-4ms]
        F[Cross-DB Operation: 15-40ms]
        G[FTS Search: 4-12ms]
        H[Vector Search: 8-20ms]
        I[Cache Operations: 1-3ms]
    end
    
    A -.->|Similar| E
    B -.->|Slower| F
    C -.->|Faster| G
    D -.->|Similar| H
    
    style A fill:#c8e6c9
    style B fill:#c8e6c9
    style E fill:#c8e6c9
    style F fill:#ffcdd2
    style G fill:#c8e6c9
    style I fill:#c8e6c9
```

### 4.2. Memory Usage Distribution

```mermaid
pie title Current Memory Usage (70MB)
    "Database Cache" : 64
    "Connection Pool" : 5
    "Other" : 1

pie title Proposed Memory Usage (95MB)
    "Main DB Cache" : 32
    "Chinook DB Cache" : 32
    "Cache DB (Memory)" : 16
    "Connection Pools" : 15
```

## 5. Extension Integration Diagrams

### 5.1. FTS5 Integration Architecture

```mermaid
graph TB
    subgraph "Chinook Database"
        A[chinook_tracks]
        B[chinook_albums]
        C[chinook_artists]
        
        D[tracks_fts Virtual Table]
        E[albums_fts Virtual Table]
        
        A -->|triggers| D
        B -->|triggers| E
        C -.->|referenced| D
        C -.->|referenced| E
    end
    
    subgraph "Search Interface"
        F[Search Controller]
        G[FTS Query Builder]
        H[Result Ranker]
    end
    
    F --> G
    G --> D
    G --> E
    D --> H
    E --> H
    H --> F
    
    style D fill:#fff3e0
    style E fill:#fff3e0
```

### 5.2. Vector Search Integration

```mermaid
graph TB
    subgraph "Vector Processing Pipeline"
        A[Audio Files] --> B[Feature Extraction]
        B --> C[Embedding Model]
        C --> D[Vector Storage]
    end
    
    subgraph "Chinook Database"
        E[chinook_tracks]
        F[track_vectors Virtual Table]
        G[similarity_cache]
        
        E -->|id mapping| F
        F --> G
    end
    
    subgraph "Search Interface"
        H[Vector Search API]
        I[Similarity Calculator]
        J[Recommendation Engine]
    end
    
    D --> F
    H --> I
    I --> F
    F --> J
    J --> H
    
    style F fill:#e8f5e8
    style G fill:#e8f5e8
```

## 6. Migration Flow Diagrams

### 6.1. Data Migration Strategy

```mermaid
graph TD
    A[Current Single Database] --> B{Backup Created?}
    B -->|No| C[Create Backup]
    B -->|Yes| D[Analyze Dependencies]
    C --> D
    
    D --> E[Create Target Databases]
    E --> F[Migrate Schema]
    F --> G[Export Data]
    G --> H[Transform Data]
    H --> I[Import to Target DBs]
    
    I --> J{Validation Passed?}
    J -->|No| K[Rollback]
    J -->|Yes| L[Update Application]
    
    L --> M{Testing Passed?}
    M -->|No| K
    M -->|Yes| N[Deploy]
    
    K --> O[Restore Backup]
    O --> P[Investigate Issues]
    
    style A fill:#e1f5fe
    style E fill:#f3e5f5
    style K fill:#ffcdd2
    style N fill:#c8e6c9
```

### 6.2. Rollback Procedure

```mermaid
graph LR
    A[Issue Detected] --> B[Stop Application]
    B --> C[Backup Current State]
    C --> D[Restore Original DB]
    D --> E[Revert Code Changes]
    E --> F[Restart Application]
    F --> G[Validate Functionality]
    G --> H{System Stable?}
    H -->|Yes| I[Document Issues]
    H -->|No| J[Emergency Procedures]
    
    style A fill:#ffcdd2
    style J fill:#ffcdd2
    style I fill:#c8e6c9
```

## 7. Operational Monitoring Diagrams

### 7.1. Multi-Database Monitoring Architecture

```mermaid
graph TB
    subgraph "Database Layer"
        A[(Main DB)]
        B[(Cache DB)]
        C[(Chinook DB)]
    end
    
    subgraph "Monitoring Layer"
        D[Connection Monitor]
        E[Performance Monitor]
        F[WAL Monitor]
        G[Cache Monitor]
    end
    
    subgraph "Alerting Layer"
        H[Alert Manager]
        I[Log Aggregator]
        J[Dashboard]
    end
    
    A --> D
    A --> E
    A --> F
    B --> G
    C --> D
    C --> E
    C --> F
    
    D --> H
    E --> H
    F --> H
    G --> H
    
    H --> I
    H --> J
    
    style H fill:#fff3e0
    style J fill:#e8f5e8
```

### 7.2. Backup Strategy Visualization

```mermaid
graph TD
    A[Scheduled Backup] --> B[Checkpoint WAL Files]
    B --> C[Create Timestamp]
    C --> D[Backup Main DB]
    C --> E[Backup Chinook DB]
    C --> F[Export Cache State]
    
    D --> G[Verify Main Backup]
    E --> H[Verify Chinook Backup]
    F --> I[Verify Cache Export]
    
    G --> J{All Verified?}
    H --> J
    I --> J
    
    J -->|Yes| K[Update Backup Log]
    J -->|No| L[Alert Admin]
    
    K --> M[Cleanup Old Backups]
    L --> N[Retry Backup]
    
    style J fill:#fff3e0
    style K fill:#c8e6c9
    style L fill:#ffcdd2
```

## 8. Security Architecture Diagrams

### 8.1. File Permission Structure

```mermaid
graph TB
    subgraph "Database Files"
        A[database.sqlite<br/>640 www-data:www-data]
        B[chinook.sqlite<br/>640 www-data:www-data]
        C[cache.sqlite<br/>:memory:]
    end
    
    subgraph "WAL Files"
        D[database.sqlite-wal<br/>640 www-data:www-data]
        E[chinook.sqlite-wal<br/>640 www-data:www-data]
    end
    
    subgraph "Backup Files"
        F[backup_*.sqlite<br/>600 backup:backup]
    end
    
    subgraph "Application Access"
        G[Web Server<br/>www-data]
        H[Backup Service<br/>backup]
    end
    
    G --> A
    G --> B
    G --> C
    G --> D
    G --> E
    
    H --> F
    
    style G fill:#e1f5fe
    style H fill:#fff3e0
```

### 8.2. Connection Security Model

```mermaid
graph LR
    subgraph "Application Layer"
        A[Laravel App]
        B[Connection Manager]
    end
    
    subgraph "Security Layer"
        C[File Permissions]
        D[Process Isolation]
        E[Network Isolation]
    end
    
    subgraph "Database Layer"
        F[(Main DB)]
        G[(Chinook DB)]
    end
    
    A --> B
    B --> C
    B --> D
    B --> E
    
    C --> F
    C --> G
    D --> F
    D --> G
    E --> F
    E --> G
    
    style C fill:#ffcdd2
    style D fill:#ffcdd2
    style E fill:#ffcdd2
```

## 9. Conclusion

These diagrams illustrate the complexity increase when moving from a single-database to a three-database architecture. Key observations:

1. **Relationship Complexity:** Cross-database relationships require application-level management
2. **Performance Trade-offs:** Some operations become faster, others slower
3. **Operational Overhead:** Significantly more complex monitoring and backup procedures
4. **Security Considerations:** Multiple files and connections to secure

The visual analysis supports the recommendation to enhance the current single-database architecture rather than implementing the three-database approach for the educational scope of the Chinook project.

---

**Document Version:** 1.0  
**Last Updated:** 2025-07-19  
**Related Documents:** sqlite-architecture-evaluation.md
