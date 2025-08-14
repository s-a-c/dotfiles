```mermaid
graph TD
    A[Create Migration] --> B[Define up() Method]
    A --> C[Define down() Method]
    B --> D[Run Migration]
    D --> E{Success?}
    E -->|Yes| F[Commit Migration File]
    E -->|No| G[Fix Issues]
    G --> D
    F --> H[Share with Team]
    H --> I[Team Runs Migration]
```
