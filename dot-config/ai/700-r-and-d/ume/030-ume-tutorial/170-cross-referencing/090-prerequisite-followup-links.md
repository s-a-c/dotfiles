# Prerequisite and Follow-up Links Implementation

<link rel="stylesheet" href="../assets/css/styles.css">

This document provides comprehensive guidance for implementing prerequisite and follow-up links throughout the UME tutorial documentation. It covers design, implementation strategies, and best practices for creating effective learning pathways that enhance the user experience.

## Purpose of Prerequisite and Follow-up Links

Prerequisite and follow-up links serve several important purposes in documentation:

1. **Learning Sequence**: Guide users through a logical learning sequence
2. **Knowledge Building**: Ensure users have necessary foundational knowledge
3. **Continuity**: Provide clear paths for continued learning
4. **Completeness**: Help users access all relevant information on a topic
5. **Orientation**: Help users understand where they are in the learning journey

## Types of Prerequisite and Follow-up Links

The UME documentation will implement several types of prerequisite and follow-up links:

### 1. Header Section Prerequisites

Prerequisites listed at the beginning of a document:

```html
<section class="prerequisites">
  <h2>Prerequisites</h2>
  <p>Before continuing with this guide, ensure you understand:</p>
  <ul>
    <li><a href="../020-models/010-user-model.md">User Model Basics</a></li>
    <li><a href="../020-models/020-database-schema.md">Database Schema</a></li>
  </ul>
</section>
```

### 2. Footer Section Follow-ups

Follow-up links listed at the end of a document:

```html
<section class="follow-ups">
  <h2>Next Steps</h2>
  <p>After completing this guide, you may want to explore:</p>
  <ul>
    <li><a href="../020-models/040-user-types.md">Implementing User Types</a></li>
    <li><a href="../080-testing/030-testing-sti.md">Testing STI Models</a></li>
  </ul>
</section>
```

### 3. Inline Prerequisite Callouts

Callouts within the content highlighting prerequisites:

```html
<div class="callout prerequisite">
  <h4>Prerequisite: User Model</h4>
  <p>This section assumes you're familiar with the User model structure. If not, please review the <a href="../020-models/010-user-model.md">User Model documentation</a> first.</p>
</div>
```

### 4. Inline Follow-up Callouts

Callouts within the content suggesting follow-up topics:

```html
<div class="callout follow-up">
  <h4>Next Step: User Types</h4>
  <p>After implementing Single Table Inheritance, you'll need to create specific User Types. Continue to the <a href="../020-models/040-user-types.md">User Types guide</a>.</p>
</div>
```

### 5. Sequential Navigation

Next/previous navigation at the bottom of each document:

```html
<nav class="sequential-nav">
  <div class="prev">
    <a href="../020-models/020-database-schema.md">
      <span>Previous</span>
      <strong>Database Schema</strong>
    </a>
  </div>
  <div class="next">
    <a href="../020-models/040-user-types.md">
      <span>Next</span>
      <strong>User Types</strong>
    </a>
  </div>
</nav>
```

## Visual Design

### Design Principles

1. **Prominence**: Prerequisites should be prominently displayed at the beginning
2. **Clarity**: Clear visual distinction between prerequisites and follow-ups
3. **Consistency**: Consistent styling across all documents
4. **Context**: Provide context for why prerequisites are necessary
5. **Progression**: Indicate natural progression through follow-up links

### CSS Styling

#### Prerequisites Section

```css
.prerequisites {
  background-color: #f8f9fa;
  border-left: 4px solid #6610f2;
  padding: 1.25rem;
  margin: 1.5rem 0;
  border-radius: 0 0.25rem 0.25rem 0;
}

.prerequisites h2 {
  margin-top: 0;
  font-size: 1.25rem;
  color: #6610f2;
}

.prerequisites ul {
  margin-bottom: 0;
}

.prerequisites li {
  margin-bottom: 0.5rem;
}

.prerequisites a {
  color: #6610f2;
  text-decoration: none;
}

.prerequisites a:hover {
  text-decoration: underline;
}
```

#### Follow-ups Section

```css
.follow-ups {
  background-color: #f8f9fa;
  border-left: 4px solid #20c997;
  padding: 1.25rem;
  margin: 1.5rem 0;
  border-radius: 0 0.25rem 0.25rem 0;
}

.follow-ups h2 {
  margin-top: 0;
  font-size: 1.25rem;
  color: #20c997;
}

.follow-ups ul {
  margin-bottom: 0;
}

.follow-ups li {
  margin-bottom: 0.5rem;
}

.follow-ups a {
  color: #20c997;
  text-decoration: none;
}

.follow-ups a:hover {
  text-decoration: underline;
}
```

#### Prerequisite Callout

```css
.callout.prerequisite {
  background-color: #f3e5f5;
  border-left: 4px solid #6610f2;
  padding: 1.25rem;
  margin: 1.5rem 0;
  border-radius: 0 0.25rem 0.25rem 0;
}

.callout.prerequisite h4 {
  margin-top: 0;
  color: #6610f2;
}

.callout.prerequisite p:last-child {
  margin-bottom: 0;
}
```

#### Follow-up Callout

```css
.callout.follow-up {
  background-color: #e0f7f1;
  border-left: 4px solid #20c997;
  padding: 1.25rem;
  margin: 1.5rem 0;
  border-radius: 0 0.25rem 0.25rem 0;
}

.callout.follow-up h4 {
  margin-top: 0;
  color: #20c997;
}

.callout.follow-up p:last-child {
  margin-bottom: 0;
}
```

## Implementation Strategy

### 1. Defining Learning Sequences

The first step is to define clear learning sequences:

1. **Topic Mapping**: Map all topics in the documentation
2. **Dependency Analysis**: Identify dependencies between topics
3. **Sequence Definition**: Define logical learning sequences
4. **Validation**: Validate sequences with subject matter experts

### 2. Prerequisite Implementation

For implementing prerequisites:

#### Metadata Approach

Include prerequisite metadata in document frontmatter:

```yaml
---
title: Single Table Inheritance
prerequisites:
  - title: User Model Basics
    url: ../020-models/010-user-model.md
    reason: Understanding the User model is essential for implementing STI
  - title: Database Schema
    url: ../020-models/020-database-schema.md
    reason: You'll need to understand the database structure for STI
---
```

#### Implementation Process

1. Define prerequisites for each document
2. Add prerequisite metadata to document frontmatter
3. Create templates for rendering prerequisites
4. Implement prerequisite rendering in documentation build process

### 3. Follow-up Implementation

For implementing follow-ups:

#### Metadata Approach

Include follow-up metadata in document frontmatter:

```yaml
---
title: Single Table Inheritance
follow_ups:
  - title: User Types
    url: ../020-models/040-user-types.md
    reason: Next step in implementing user type hierarchy
  - title: Testing STI Models
    url: ../080-testing/030-testing-sti.md
    reason: Learn how to test your STI implementation
---
```

#### Implementation Process

1. Define follow-ups for each document
2. Add follow-up metadata to document frontmatter
3. Create templates for rendering follow-ups
4. Implement follow-up rendering in documentation build process

### 4. Sequential Navigation

For implementing sequential navigation:

#### Sequence Definition

Define the sequence for each section in a configuration file:

```yaml
models_sequence:
  - title: Models Overview
    url: ../020-models/000-index.md
  - title: User Model Basics
    url: ../020-models/010-user-model.md
  - title: Database Schema
    url: ../020-models/020-database-schema.md
  - title: Single Table Inheritance
    url: ../020-models/030-single-table-inheritance.md
  - title: User Types
    url: ../020-models/040-user-types.md
```

#### Implementation Process

1. Define sequences for each section
2. Create configuration files for sequences
3. Implement sequential navigation rendering
4. Add sequential navigation to document templates

## Prerequisite Types

Different types of prerequisites serve different purposes:

### 1. Knowledge Prerequisites

Prerequisites for conceptual understanding:

```html
<div class="callout prerequisite">
  <h4>Knowledge Prerequisite: Object-Oriented Programming</h4>
  <p>This guide assumes you have a solid understanding of object-oriented programming concepts, including inheritance and polymorphism.</p>
</div>
```

### 2. Implementation Prerequisites

Prerequisites for implementation steps:

```html
<div class="callout prerequisite">
  <h4>Implementation Prerequisite: User Model</h4>
  <p>Before implementing Single Table Inheritance, you must have the User model set up. See the <a href="../020-models/010-user-model.md">User Model guide</a>.</p>
</div>
```

### 3. Tool Prerequisites

Prerequisites for tools or environment:

```html
<div class="callout prerequisite">
  <h4>Tool Prerequisite: Laravel 10</h4>
  <p>This guide assumes you're using Laravel 10. Earlier versions may require different approaches.</p>
</div>
```

## Follow-up Types

Different types of follow-ups serve different purposes:

### 1. Next Steps

Direct next steps in the learning sequence:

```html
<div class="callout follow-up">
  <h4>Next Step: User Types</h4>
  <p>After implementing Single Table Inheritance, continue to <a href="../020-models/040-user-types.md">User Types</a> to create specific user type models.</p>
</div>
```

### 2. Advanced Topics

Follow-ups for advanced exploration:

```html
<div class="callout follow-up">
  <h4>Advanced Topic: STI Performance Optimization</h4>
  <p>For large applications, explore <a href="../060-advanced/020-advanced-sti.md">Advanced STI Techniques</a> to optimize performance.</p>
</div>
```

### 3. Related Topics

Follow-ups for related but not sequential topics:

```html
<div class="callout follow-up">
  <h4>Related Topic: Polymorphic Relationships</h4>
  <p>You might also be interested in <a href="../020-models/050-polymorphic-relationships.md">Polymorphic Relationships</a>, an alternative approach for model relationships.</p>
</div>
```

## Examples

### Example 1: Prerequisites for Single Table Inheritance

```html
<section class="prerequisites">
  <h2>Prerequisites</h2>
  <p>Before continuing with this guide, ensure you understand:</p>
  <ul>
    <li><a href="../020-models/010-user-model.md">User Model Basics</a> - Understanding the User model is essential for implementing STI</li>
    <li><a href="../020-models/020-database-schema.md">Database Schema</a> - You'll need to understand the database structure for STI</li>
    <li><a href="../010-getting-started/040-eloquent.md">Eloquent ORM Basics</a> - Familiarity with Eloquent ORM is required</li>
  </ul>
</section>

<div class="callout prerequisite">
  <h4>Knowledge Prerequisite: Inheritance</h4>
  <p>This guide assumes you understand object-oriented inheritance concepts. If you need a refresher, see the <a href="../010-getting-started/030-oop-concepts.md">OOP Concepts guide</a>.</p>
</div>
```

### Example 2: Follow-ups for Authentication

```html
<section class="follow-ups">
  <h2>Next Steps</h2>
  <p>After implementing basic authentication, you may want to explore:</p>
  <ul>
    <li><a href="../030-authentication/030-two-factor-auth.md">Two-Factor Authentication</a> - Add an extra layer of security</li>
    <li><a href="../030-authentication/040-user-profiles.md">User Profiles</a> - Implement customizable user profiles</li>
    <li><a href="../030-authentication/050-password-policies.md">Password Policies</a> - Enforce strong password requirements</li>
  </ul>
</section>

<div class="callout follow-up">
  <h4>Next Step: Two-Factor Authentication</h4>
  <p>For enhanced security, implement <a href="../030-authentication/030-two-factor-auth.md">Two-Factor Authentication</a> after basic authentication is working.</p>
</div>
```

### Example 3: Sequential Navigation for Teams

```html
<nav class="sequential-nav">
  <div class="prev">
    <a href="../040-teams/020-team-model.md">
      <span>Previous</span>
      <strong>Team Model</strong>
    </a>
  </div>
  <div class="next">
    <a href="../040-teams/040-team-permissions.md">
      <span>Next</span>
      <strong>Team Permissions</strong>
    </a>
  </div>
</nav>
```

## Mobile Considerations

On mobile devices, prerequisite and follow-up links should be adapted:

### Responsive Design

1. **Prerequisites/Follow-ups**: Maintain but with adjusted sizing
2. **Callouts**: Ensure proper sizing and readability
3. **Sequential Navigation**: Adjust for smaller screens

### Mobile-Specific CSS

```css
@media (max-width: 768px) {
  .prerequisites,
  .follow-ups {
    padding: 1rem;
    margin: 1rem 0;
  }
  
  .callout.prerequisite,
  .callout.follow-up {
    padding: 1rem;
    margin: 1rem 0;
  }
  
  .sequential-nav {
    flex-direction: column;
    gap: 0.5rem;
  }
  
  .sequential-nav .prev,
  .sequential-nav .next {
    max-width: 100%;
  }
}
```

## Implementation Process

The implementation of prerequisite and follow-up links will follow these steps:

### 1. Learning Sequence Definition

1. Map all topics in the documentation
2. Identify dependencies between topics
3. Define logical learning sequences
4. Create sequence configuration files

### 2. Metadata Addition

1. Define prerequisites and follow-ups for each document
2. Add metadata to document frontmatter
3. Create templates for rendering prerequisites and follow-ups

### 3. Template Updates

1. Update documentation templates to include prerequisite and follow-up sections
2. Add CSS styling for prerequisites and follow-ups
3. Implement sequential navigation

### 4. Content Updates

1. Add inline prerequisite and follow-up callouts at appropriate points
2. Ensure consistency across related documents
3. Validate learning sequences

### 5. Testing and Validation

1. Test prerequisite and follow-up links on all document types
2. Verify correct relationships and sequences
3. Test on different devices and screen sizes
4. Validate accessibility compliance

## Maintenance Guidelines

To maintain effective prerequisite and follow-up links:

1. **Update with Content Changes**: When content is added, moved, or removed, update affected links
2. **Verify Sequences**: Regularly check learning sequences for logical flow
3. **Review Prerequisites**: Ensure prerequisites remain relevant and necessary
4. **Monitor Usage**: Use analytics to understand how users follow learning paths
5. **Gather Feedback**: Collect user feedback on the usefulness of learning sequences

## Integration with Other Navigation

Prerequisite and follow-up links work alongside other navigation elements:

### 1. Learning Paths

Learning paths provide structured courses, while prerequisite and follow-up links provide contextual guidance within individual documents.

### 2. Breadcrumbs

Breadcrumbs show hierarchical location, while prerequisite and follow-up links show learning sequences.

### 3. "See Also" Sections

"See Also" sections provide comprehensive related content, while follow-up links highlight specific next steps.

### 4. Contextual Navigation

Contextual navigation provides in-context links, while prerequisite and follow-up links provide structured learning paths.

## Measuring Effectiveness

To measure the effectiveness of prerequisite and follow-up links:

1. **Sequence Adherence**: Percentage of users who follow recommended sequences
2. **Prerequisite Access**: Percentage of users who access prerequisites before main content
3. **Follow-up Engagement**: Percentage of users who continue to follow-up content
4. **Completion Rates**: Percentage of users who complete entire learning sequences
5. **User Feedback**: Direct feedback on the usefulness of learning sequences

## Conclusion

Implementing prerequisite and follow-up links throughout the UME documentation will significantly enhance the learning experience by providing clear learning paths, ensuring users have necessary foundational knowledge, and guiding them through logical learning sequences. By following these guidelines, the documentation will become more structured, navigable, and effective as a learning resource.

## See Also

- [Cross-Reference Audit](010-cross-reference-audit.md) - Review of the current cross-referencing system
- [Improved Cross-Reference System](020-improved-cross-reference-system.md) - Standards for cross-references
- [Concept Relationship Map](030-concept-relationship-map.md) - Visual map of concept relationships
- ["See Also" Sections Implementation](040-see-also-sections.md) - Guidelines for implementing "See Also" sections
- [Tagging System](050-tagging-system.md) - Tagging system for related concepts
- [Breadcrumb Navigation](060-breadcrumb-navigation.md) - Implementation of breadcrumb navigation
- [Contextual Navigation](070-contextual-navigation.md) - Implementation of contextual navigation
- [Related Content Suggestions](080-related-content-suggestions.md) - Implementation of related content suggestions
