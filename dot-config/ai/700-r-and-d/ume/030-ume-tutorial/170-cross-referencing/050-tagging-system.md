# Tagging System for Related Concepts

<link rel="stylesheet" href="../assets/css/styles.css">

This document outlines a comprehensive tagging system for UME documentation, designed to improve content discoverability, enhance navigation, and create meaningful connections between related concepts.

## Purpose of the Tagging System

The UME documentation tagging system serves several key purposes:

1. **Improved Discoverability**: Help users find related content through tags
2. **Conceptual Grouping**: Group content by concepts rather than just document structure
3. **Alternative Navigation**: Provide navigation paths beyond hierarchical structure
4. **Relationship Identification**: Highlight relationships between different topics
5. **Search Enhancement**: Improve search functionality with tag-based filtering

## Tag Categories

The UME tagging system uses the following categories of tags:

### 1. Concept Tags

Tags that represent core concepts in the UME system.

**Examples**: `user-model`, `single-table-inheritance`, `authentication`, `teams`, `permissions`, `state-machines`, `real-time`

### 2. Feature Tags

Tags that represent specific features within broader concepts.

**Examples**: `two-factor-auth`, `team-hierarchy`, `user-presence`, `file-uploads`, `api-authentication`

### 3. Implementation Tags

Tags that represent implementation approaches or technologies.

**Examples**: `laravel`, `eloquent`, `livewire`, `alpine-js`, `websockets`, `blade-components`

### 4. Skill Level Tags

Tags that indicate the skill level required for the content.

**Examples**: `beginner`, `intermediate`, `advanced`

### 5. Content Type Tags

Tags that indicate the type of content.

**Examples**: `tutorial`, `reference`, `guide`, `api`, `example`, `troubleshooting`

## Tag Format and Standards

To ensure consistency and usability, all tags must follow these standards:

### Format Rules

1. **Lowercase**: All tags must be lowercase
2. **Hyphenated**: Multi-word tags use hyphens (e.g., `user-model`)
3. **Singular Form**: Use singular form for consistency (e.g., `team` not `teams`)
4. **No Spaces**: No spaces allowed in tags
5. **ASCII Characters**: Only ASCII characters allowed

### Naming Conventions

1. **Consistency**: Use consistent terminology across tags
2. **Specificity**: Be specific enough to be useful but not too narrow
3. **Clarity**: Use clear, unambiguous terms
4. **Brevity**: Keep tags concise (1-3 words)
5. **Established Terms**: Use terminology established in the documentation

## Core Tag List

The following core tags have been defined for the UME documentation:

### Concept Tags

| Tag | Description | Related Concepts |
|-----|-------------|------------------|
| `user-model` | Core user model functionality | `eloquent`, `model`, `database` |
| `single-table-inheritance` | Single Table Inheritance pattern | `inheritance`, `user-type`, `polymorphism` |
| `authentication` | User authentication | `login`, `registration`, `password` |
| `team` | Team management | `team-hierarchy`, `team-member`, `organization` |
| `permission` | Permission system | `role`, `policy`, `authorization` |
| `state-machine` | State machine implementation | `user-state`, `team-state`, `transition` |
| `real-time` | Real-time features | `websocket`, `broadcasting`, `presence` |
| `api` | API functionality | `rest`, `resource`, `endpoint` |
| `testing` | Testing functionality | `unit-test`, `feature-test`, `browser-test` |
| `deployment` | Deployment processes | `docker`, `ci-cd`, `environment` |

### Feature Tags

| Tag | Description | Related Concepts |
|-----|-------------|------------------|
| `user-type` | User type implementation | `single-table-inheritance`, `polymorphism` |
| `trait` | Reusable traits | `has-ulid`, `has-user-tracking` |
| `two-factor-auth` | Two-factor authentication | `authentication`, `security` |
| `user-profile` | User profile management | `user-model`, `file-upload` |
| `team-hierarchy` | Team hierarchy implementation | `team`, `nested-set` |
| `team-member` | Team membership management | `team`, `invitation` |
| `role-based-access` | Role-based access control | `permission`, `role` |
| `state-transition` | State transitions | `state-machine`, `event` |
| `websocket` | WebSocket implementation | `real-time`, `connection` |
| `presence` | User presence functionality | `real-time`, `online-status` |
| `activity-tracking` | Activity tracking | `real-time`, `audit` |
| `multi-tenancy` | Multi-tenancy implementation | `tenant`, `isolation` |
| `file-upload` | File upload functionality | `storage`, `media` |
| `search` | Search functionality | `indexing`, `query` |

### Implementation Tags

| Tag | Description | Related Concepts |
|-----|-------------|------------------|
| `laravel` | Laravel framework | `php`, `framework` |
| `eloquent` | Eloquent ORM | `model`, `database` |
| `blade` | Blade templating | `view`, `component` |
| `livewire` | Livewire components | `component`, `reactive` |
| `alpine-js` | Alpine.js | `javascript`, `reactive` |
| `tailwind` | Tailwind CSS | `css`, `styling` |
| `fortify` | Laravel Fortify | `authentication`, `scaffolding` |
| `reverb` | Laravel Reverb | `websocket`, `real-time` |
| `spatie-permission` | Spatie Permission package | `permission`, `role` |
| `spatie-media-library` | Spatie Media Library | `file-upload`, `media` |
| `php8` | PHP 8 features | `attribute`, `constructor-promotion` |
| `mysql` | MySQL database | `database`, `query` |
| `redis` | Redis | `cache`, `queue` |
| `docker` | Docker | `container`, `deployment` |

### Skill Level Tags

| Tag | Description | Prerequisites |
|-----|-------------|---------------|
| `beginner` | Suitable for beginners | Basic PHP and Laravel knowledge |
| `intermediate` | Requires intermediate knowledge | Solid Laravel experience |
| `advanced` | Advanced concepts | Extensive Laravel experience |

### Content Type Tags

| Tag | Description | Typical Usage |
|-----|-------------|---------------|
| `tutorial` | Step-by-step instructions | Implementation guides |
| `reference` | Reference documentation | API documentation |
| `guide` | Conceptual guidance | Best practices |
| `example` | Code examples | Implementation examples |
| `troubleshooting` | Troubleshooting information | Common issues and solutions |
| `api` | API documentation | Endpoint documentation |
| `configuration` | Configuration information | Setup instructions |
| `best-practice` | Best practices | Recommendations |

## Tag Implementation

Tags will be implemented in the UME documentation using the following approach:

### Metadata Format

Tags will be included in document metadata using YAML frontmatter:

```yaml
---
title: Single Table Inheritance
tags:
  - user-model
  - single-table-inheritance
  - inheritance
  - eloquent
  - intermediate
  - guide
---
```

### Tag Display

Tags will be displayed at the top of each document:

```html
<div class="tags">
  <span class="tag concept">user-model</span>
  <span class="tag concept">single-table-inheritance</span>
  <span class="tag implementation">eloquent</span>
  <span class="tag skill">intermediate</span>
  <span class="tag content">guide</span>
</div>
```

### Tag Styling

Tags will be styled according to their category:

```css
.tag {
  display: inline-block;
  padding: 0.25rem 0.5rem;
  border-radius: 0.25rem;
  font-size: 0.75rem;
  font-weight: 600;
  margin-right: 0.5rem;
  margin-bottom: 0.5rem;
}

.tag.concept {
  background-color: #e3f2fd;
  color: #0d47a1;
}

.tag.feature {
  background-color: #e8f5e9;
  color: #1b5e20;
}

.tag.implementation {
  background-color: #fff3e0;
  color: #e65100;
}

.tag.skill {
  background-color: #f3e5f5;
  color: #4a148c;
}

.tag.content {
  background-color: #e0f2f1;
  color: #004d40;
}
```

## Tag Navigation

The tagging system will support navigation in several ways:

### Tag Pages

Each tag will have a dedicated page that lists all content with that tag:

```
/tags/user-model.html
/tags/single-table-inheritance.html
/tags/intermediate.html
```

### Tag Filtering

The documentation search will support filtering by tags:

```
?tags=user-model,intermediate
```

### Tag Clouds

Tag clouds will be displayed in appropriate locations:

```html
<div class="tag-cloud">
  <h3>Popular Tags</h3>
  <div class="tags">
    <a href="/tags/user-model.html" class="tag concept">user-model (42)</a>
    <a href="/tags/authentication.html" class="tag concept">authentication (38)</a>
    <a href="/tags/team.html" class="tag concept">team (35)</a>
    <!-- More tags... -->
  </div>
</div>
```

### Related Tags

Each tag page will show related tags:

```html
<div class="related-tags">
  <h3>Related Tags</h3>
  <div class="tags">
    <a href="/tags/eloquent.html" class="tag implementation">eloquent</a>
    <a href="/tags/model.html" class="tag concept">model</a>
    <a href="/tags/database.html" class="tag concept">database</a>
    <!-- More related tags... -->
  </div>
</div>
```

## Tag Assignment Guidelines

To ensure consistent and effective tagging, follow these guidelines:

### Number of Tags

- **Minimum**: Each document should have at least 3 tags
- **Maximum**: Each document should have no more than 10 tags
- **Optimal**: 5-7 tags per document is ideal

### Tag Selection

1. **Required Categories**: Each document must include at least:
   - One concept tag
   - One skill level tag
   - One content type tag

2. **Relevance**: Only assign tags that are directly relevant to the content
3. **Specificity**: Use the most specific tags applicable
4. **Consistency**: Use consistent tags across related documents
5. **Completeness**: Ensure all relevant aspects are tagged

### Tag Review Process

All tag assignments should be reviewed for:

1. **Accuracy**: Tags accurately represent the content
2. **Consistency**: Tags are consistent with related documents
3. **Completeness**: All relevant tags are included
4. **Compliance**: Tags follow the format and standards
5. **Usefulness**: Tags enhance discoverability and navigation

## Tag Implementation Process

The implementation of the tagging system will follow these steps:

### 1. Initial Tag Assignment

1. Review each document and assign appropriate tags
2. Ensure compliance with tag assignment guidelines
3. Review for consistency across related documents
4. Document tag assignments for review

### 2. Tag Infrastructure Implementation

1. Update documentation templates to include tag metadata
2. Implement tag display styling
3. Create tag pages for each tag
4. Implement tag filtering in search
5. Create tag clouds and related tag displays

### 3. Tag Review and Refinement

1. Review initial tag assignments
2. Refine tags based on review feedback
3. Ensure consistency across the documentation
4. Update tag list as needed

### 4. Tag Maintenance

1. Review tags quarterly
2. Update tags as content changes
3. Add new tags as needed
4. Remove obsolete tags
5. Maintain tag consistency

## Example Tag Assignments

### Example 1: User Model Documentation

```yaml
---
title: User Model
tags:
  - user-model
  - eloquent
  - model
  - database
  - beginner
  - guide
---
```

### Example 2: Single Table Inheritance Tutorial

```yaml
---
title: Implementing Single Table Inheritance
tags:
  - single-table-inheritance
  - user-model
  - user-type
  - inheritance
  - eloquent
  - intermediate
  - tutorial
---
```

### Example 3: Authentication API Reference

```yaml
---
title: Authentication API
tags:
  - authentication
  - api
  - rest
  - endpoint
  - security
  - intermediate
  - reference
---
```

### Example 4: Team Hierarchy Implementation

```yaml
---
title: Implementing Team Hierarchy
tags:
  - team
  - team-hierarchy
  - nested-set
  - relationship
  - advanced
  - tutorial
  - example
---
```

### Example 5: Real-time Features Guide

```yaml
---
title: Real-time Features Overview
tags:
  - real-time
  - websocket
  - broadcasting
  - presence
  - reverb
  - intermediate
  - guide
---
```

## Tag Governance

To maintain the integrity and usefulness of the tagging system:

### Tag Addition Process

New tags can be proposed through:

1. Documentation team review
2. User feedback
3. Content analysis

New tags must be:

1. Consistent with existing tags
2. Useful for navigation and discovery
3. Clear and unambiguous
4. Not redundant with existing tags

### Tag Deprecation Process

Tags can be deprecated when:

1. They are no longer relevant
2. They are redundant with other tags
3. They are too specific or too general
4. They are inconsistent with naming conventions

Deprecated tags should:

1. Be marked as deprecated
2. Have content re-tagged with appropriate tags
3. Eventually be removed from the system

## Conclusion

The UME documentation tagging system provides a powerful way to connect related concepts, improve content discoverability, and enhance navigation. By following the guidelines and standards outlined in this document, the tagging system will create a more interconnected and accessible documentation experience.

## See Also

- [Cross-Reference Audit](010-cross-reference-audit.md) - Review of the current cross-referencing system
- [Improved Cross-Reference System](020-improved-cross-reference-system.md) - Standards for cross-references
- [Concept Relationship Map](030-concept-relationship-map.md) - Visual map of concept relationships
- ["See Also" Sections Implementation](040-see-also-sections.md) - Guidelines for implementing "See Also" sections
- [Documentation Standards](../070-documentation/010-standards.md) - Overall documentation standards
