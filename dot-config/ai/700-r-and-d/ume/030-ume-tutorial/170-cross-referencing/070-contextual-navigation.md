# Contextual Navigation Implementation

<link rel="stylesheet" href="../assets/css/styles.css">

This document provides comprehensive guidance for implementing contextual navigation throughout the UME tutorial documentation. It covers design, implementation strategies, and best practices for creating effective contextual navigation that enhances the user experience.

## Purpose of Contextual Navigation

Contextual navigation serves several important purposes in documentation:

1. **Relevance**: Provides navigation options specifically relevant to the current content
2. **Discovery**: Helps users discover related content they might not otherwise find
3. **Learning Flow**: Supports natural learning progression through related topics
4. **Reduced Search**: Decreases the need for users to search for related information
5. **Engagement**: Increases engagement by suggesting valuable next steps

## Types of Contextual Navigation

The UME documentation will implement several types of contextual navigation:

### 1. In-Content Links

Contextual links embedded within the content text:

```markdown
The [User Model](../020-models/010-user-model.md) serves as the foundation for 
[Single Table Inheritance](../020-models/030-single-table-inheritance.md), 
allowing different user types to share a common database table.
```

### 2. Related Content Sidebars

Sidebar widgets showing related content based on the current page:

```html
<aside class="related-content">
  <h3>Related Content</h3>
  <ul>
    <li><a href="../020-models/010-user-model.md">User Model</a></li>
    <li><a href="../020-models/040-user-types.md">User Types</a></li>
    <li><a href="../020-models/050-polymorphic-relationships.md">Polymorphic Relationships</a></li>
  </ul>
</aside>
```

### 3. Next/Previous Navigation

Navigation links to move sequentially through content:

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

### 4. Contextual Callouts

Highlighted boxes with contextual information and links:

```html
<div class="callout info">
  <h4>Working with User Types</h4>
  <p>After implementing Single Table Inheritance, you'll need to create specific User Types.</p>
  <p><a href="../020-models/040-user-types.md">Learn about User Types →</a></p>
</div>
```

### 5. Contextual Tabs

Tabbed interface for different aspects of the same topic:

```html
<div class="contextual-tabs">
  <nav class="tabs">
    <a href="#overview" class="active">Overview</a>
    <a href="#implementation">Implementation</a>
    <a href="#examples">Examples</a>
    <a href="#troubleshooting">Troubleshooting</a>
  </nav>
  <div class="tab-content">
    <!-- Tab content here -->
  </div>
</div>
```

## Contextual Navigation Design

### Visual Design Principles

1. **Distinction**: Contextual navigation should be visually distinct from main content
2. **Consistency**: Use consistent styling across all contextual navigation elements
3. **Hierarchy**: Visual hierarchy should reflect the importance of navigation options
4. **Clarity**: Clear labels and icons to indicate the purpose of navigation elements
5. **Unobtrusiveness**: Should enhance, not distract from, the main content

### CSS Styling

#### Related Content Sidebar

```css
.related-content {
  background-color: #f8f9fa;
  border-left: 4px solid #007bff;
  padding: 1rem;
  margin: 1.5rem 0;
  border-radius: 0 0.25rem 0.25rem 0;
}

.related-content h3 {
  margin-top: 0;
  font-size: 1.25rem;
  color: #343a40;
}

.related-content ul {
  margin: 0;
  padding-left: 1.25rem;
}

.related-content li {
  margin-bottom: 0.5rem;
}

.related-content a {
  color: #007bff;
  text-decoration: none;
}

.related-content a:hover {
  text-decoration: underline;
}
```

#### Next/Previous Navigation

```css
.sequential-nav {
  display: flex;
  justify-content: space-between;
  margin: 2rem 0;
  border-top: 1px solid #dee2e6;
  border-bottom: 1px solid #dee2e6;
  padding: 1rem 0;
}

.sequential-nav .prev,
.sequential-nav .next {
  max-width: 45%;
}

.sequential-nav a {
  display: block;
  color: #212529;
  text-decoration: none;
  padding: 0.5rem;
  border-radius: 0.25rem;
  transition: background-color 0.2s;
}

.sequential-nav a:hover {
  background-color: #f8f9fa;
}

.sequential-nav span {
  display: block;
  font-size: 0.875rem;
  color: #6c757d;
}

.sequential-nav strong {
  display: block;
  font-size: 1.125rem;
  color: #007bff;
}

.sequential-nav .prev a {
  text-align: left;
}

.sequential-nav .next a {
  text-align: right;
}
```

#### Contextual Callouts

```css
.callout {
  padding: 1.25rem;
  margin: 1.5rem 0;
  border-radius: 0.25rem;
  border-left: 4px solid #6c757d;
}

.callout h4 {
  margin-top: 0;
  margin-bottom: 0.5rem;
}

.callout p:last-child {
  margin-bottom: 0;
}

.callout.info {
  background-color: #e3f2fd;
  border-left-color: #007bff;
}

.callout.warning {
  background-color: #fff3cd;
  border-left-color: #ffc107;
}

.callout.success {
  background-color: #d4edda;
  border-left-color: #28a745;
}

.callout.danger {
  background-color: #f8d7da;
  border-left-color: #dc3545;
}
```

## Implementation Strategy

### 1. In-Content Links

#### Guidelines for In-Content Links

1. Link key concepts and terms to their primary documentation
2. Use descriptive link text that indicates the destination
3. Avoid generic link text like "click here" or "read more"
4. Don't overlink - focus on the most relevant connections
5. Ensure links are contextually relevant to the surrounding content

#### Implementation Process

1. Identify key concepts and terms in each document
2. Create links to the primary documentation for each concept
3. Review for relevance and avoid overlinking
4. Ensure consistent linking across related documents

### 2. Related Content Sidebars

#### Content Selection Criteria

Related content should be selected based on:

1. **Conceptual Relationship**: Content about related concepts
2. **Implementation Relationship**: Content about related implementation aspects
3. **Learning Progression**: Content that represents next steps in learning
4. **Common Usage**: Content commonly used together
5. **Complementary Information**: Content that provides additional context

#### Implementation Process

1. For each document, identify 3-5 most closely related documents
2. Create a related content sidebar with links to these documents
3. Add brief descriptions explaining the relationship
4. Place the sidebar in a consistent location (typically right side)
5. Ensure mobile responsiveness

### 3. Next/Previous Navigation

#### Sequence Determination

The sequence for next/previous navigation should be determined by:

1. **Natural Learning Progression**: Logical order for learning the content
2. **Implementation Order**: Order in which features would be implemented
3. **Directory Structure**: Order within the documentation structure
4. **Complexity Level**: Progression from basic to advanced topics

#### Implementation Process

1. Define the sequence for each section of documentation
2. Create next/previous links based on this sequence
3. Add descriptive titles to indicate the content of linked pages
4. Place navigation at the bottom of each document
5. Ensure consistent implementation across all documents

### 4. Contextual Callouts

#### Callout Types

Different types of callouts serve different purposes:

1. **Info Callouts**: Provide additional information and context
2. **Warning Callouts**: Highlight potential issues or considerations
3. **Success Callouts**: Showcase best practices or optimal approaches
4. **Danger Callouts**: Warn about critical issues or pitfalls

#### Implementation Process

1. Identify opportunities for contextual callouts in each document
2. Create appropriate callouts with relevant information
3. Include contextual links to related documentation
4. Place callouts at relevant points within the content
5. Ensure callouts add value without disrupting the flow

### 5. Contextual Tabs

#### Tab Organization

Tabs should be organized based on:

1. **Content Type**: Different types of content about the same topic
2. **Implementation Aspects**: Different aspects of implementation
3. **Skill Levels**: Content tailored to different skill levels
4. **Use Cases**: Different use cases for the same feature

#### Implementation Process

1. Identify content that would benefit from tabbed organization
2. Create tab structure with clear, descriptive labels
3. Organize content within appropriate tabs
4. Ensure tab content is complete and self-contained
5. Implement tab switching functionality

## Examples

### Example 1: In-Content Links

```markdown
## Single Table Inheritance

Single Table Inheritance (STI) is a pattern that allows multiple model classes to share a single database table. In the UME system, this is used to implement different [user types](../020-models/040-user-types.md) such as Admin, Manager, and Practitioner.

The implementation relies on the [User model](../020-models/010-user-model.md) as the base class, with a [type discriminator column](../020-models/020-database-schema.md#type-discriminator) to distinguish between different user types.

For advanced scenarios, consider using [polymorphic relationships](../020-models/050-polymorphic-relationships.md) in conjunction with STI.
```

### Example 2: Related Content Sidebar

```html
<aside class="related-content">
  <h3>Related to Single Table Inheritance</h3>
  <ul>
    <li><a href="../020-models/010-user-model.md">User Model</a> - The base model for STI implementation</li>
    <li><a href="../020-models/040-user-types.md">User Types</a> - Implementing specific user types with STI</li>
    <li><a href="../020-models/050-polymorphic-relationships.md">Polymorphic Relationships</a> - Alternative approach for model relationships</li>
    <li><a href="../060-advanced/020-advanced-sti.md">Advanced STI Techniques</a> - Advanced usage and optimization</li>
    <li><a href="../080-testing/030-testing-sti.md">Testing STI Models</a> - How to test STI implementations</li>
  </ul>
</aside>
```

### Example 3: Next/Previous Navigation

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

### Example 4: Contextual Callout

```html
<div class="callout info">
  <h4>Performance Considerations</h4>
  <p>Single Table Inheritance can impact query performance with large tables. For applications with many users, consider implementing the optimization techniques described in the Advanced STI documentation.</p>
  <p><a href="../060-advanced/020-advanced-sti.md">Learn about Advanced STI Techniques →</a></p>
</div>

<div class="callout warning">
  <h4>Type Discrimination</h4>
  <p>Ensure your type discriminator column is properly indexed to maintain query performance. Without an index, queries filtering by user type can become slow as the table grows.</p>
  <p><a href="../020-models/020-database-schema.md#indexing">Learn about proper indexing →</a></p>
</div>
```

### Example 5: Contextual Tabs

```html
<div class="contextual-tabs">
  <nav class="tabs">
    <a href="#overview" class="active">Overview</a>
    <a href="#implementation">Implementation</a>
    <a href="#examples">Examples</a>
    <a href="#troubleshooting">Troubleshooting</a>
  </nav>
  <div class="tab-content">
    <div id="overview" class="tab-pane active">
      <h3>Single Table Inheritance Overview</h3>
      <p>Single Table Inheritance (STI) is a pattern that allows multiple model classes to share a single database table...</p>
    </div>
    <div id="implementation" class="tab-pane">
      <h3>Implementing Single Table Inheritance</h3>
      <p>To implement STI in your UME application, follow these steps...</p>
    </div>
    <div id="examples" class="tab-pane">
      <h3>Single Table Inheritance Examples</h3>
      <p>Here are some examples of STI implementation in different scenarios...</p>
    </div>
    <div id="troubleshooting" class="tab-pane">
      <h3>Troubleshooting Single Table Inheritance</h3>
      <p>Common issues and their solutions when working with STI...</p>
    </div>
  </div>
</div>
```

## Content-Specific Contextual Navigation

Different types of content benefit from different contextual navigation approaches:

### Concept Documentation

For concept documentation, focus on:

1. **Conceptual Relationships**: Links to related concepts
2. **Implementation Guidance**: Links to implementation details
3. **Examples**: Links to example implementations
4. **Advanced Topics**: Links to advanced aspects of the concept

### Tutorial Documentation

For tutorial documentation, focus on:

1. **Prerequisites**: Links to required knowledge
2. **Next Steps**: Links to follow-up tutorials
3. **Troubleshooting**: Links to common issues and solutions
4. **Alternative Approaches**: Links to alternative implementations

### API Documentation

For API documentation, focus on:

1. **Related Endpoints**: Links to related API endpoints
2. **Request/Response Examples**: Links to example usage
3. **Authentication**: Links to authentication requirements
4. **Error Handling**: Links to error handling guidance

### Reference Documentation

For reference documentation, focus on:

1. **Usage Examples**: Links to example usage
2. **Configuration Options**: Links to configuration details
3. **Related References**: Links to related reference material
4. **Best Practices**: Links to best practices

## Mobile Considerations

On mobile devices, contextual navigation should be adapted:

### Responsive Design

1. **Sidebars**: Convert to inline or collapsible sections
2. **Next/Previous**: Maintain but with simplified design
3. **Callouts**: Ensure proper sizing and readability
4. **Tabs**: Convert to accordion-style interface if needed

### Mobile-Specific CSS

```css
@media (max-width: 768px) {
  .related-content {
    margin: 1rem 0;
    padding: 0.75rem;
  }
  
  .sequential-nav {
    flex-direction: column;
    gap: 0.5rem;
  }
  
  .sequential-nav .prev,
  .sequential-nav .next {
    max-width: 100%;
  }
  
  .contextual-tabs .tabs {
    display: flex;
    flex-direction: column;
  }
  
  .contextual-tabs .tabs a {
    border-radius: 0;
    border-bottom: 1px solid #dee2e6;
  }
}
```

## Implementation Process

The implementation of contextual navigation will follow these steps:

### 1. Content Analysis

1. Analyze each document to identify related content
2. Map relationships between documents
3. Determine appropriate contextual navigation elements

### 2. Template Updates

1. Update documentation templates to include contextual navigation elements
2. Add CSS styling for contextual navigation
3. Implement JavaScript functionality where needed (e.g., tabs)

### 3. Content Updates

1. Add in-content links to existing documentation
2. Create related content sidebars for each document
3. Implement next/previous navigation based on defined sequences
4. Add contextual callouts at appropriate points
5. Implement contextual tabs where beneficial

### 4. Testing and Validation

1. Test contextual navigation on all document types
2. Verify correct relationships and links
3. Test on different devices and screen sizes
4. Validate accessibility compliance

## Maintenance Guidelines

To maintain effective contextual navigation:

1. **Update with Content Changes**: When content is added, moved, or removed, update affected contextual navigation
2. **Verify Links**: Regularly check contextual links for accuracy
3. **Review Relevance**: Ensure contextual navigation remains relevant and valuable
4. **Monitor Usage**: Use analytics to understand how users interact with contextual navigation
5. **Gather Feedback**: Collect user feedback on the usefulness of contextual navigation

## Integration with Other Navigation

Contextual navigation works alongside other navigation elements:

### 1. Main Navigation

Main navigation provides global structure, while contextual navigation provides local relevance.

### 2. Breadcrumbs

Breadcrumbs show hierarchical location, while contextual navigation shows conceptual relationships.

### 3. "See Also" Sections

"See Also" sections provide a comprehensive list of related content, while contextual navigation highlights the most relevant relationships within the content.

### 4. Search

Contextual navigation complements search by proactively suggesting related content.

## Conclusion

Implementing contextual navigation throughout the UME documentation will significantly enhance the user experience by providing relevant, context-specific navigation options. By following these guidelines, the documentation will become more interconnected, discoverable, and valuable for users at all levels.

## See Also

- [Cross-Reference Audit](010-cross-reference-audit.md) - Review of the current cross-referencing system
- [Improved Cross-Reference System](020-improved-cross-reference-system.md) - Standards for cross-references
- [Concept Relationship Map](030-concept-relationship-map.md) - Visual map of concept relationships
- ["See Also" Sections Implementation](040-see-also-sections.md) - Guidelines for implementing "See Also" sections
- [Tagging System](050-tagging-system.md) - Tagging system for related concepts
- [Breadcrumb Navigation](060-breadcrumb-navigation.md) - Implementation of breadcrumb navigation
