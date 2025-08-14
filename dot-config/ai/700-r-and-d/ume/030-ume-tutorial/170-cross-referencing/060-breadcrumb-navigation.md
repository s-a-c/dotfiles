# Breadcrumb Navigation Implementation

<link rel="stylesheet" href="../assets/css/styles.css">

This document provides comprehensive guidance for implementing breadcrumb navigation throughout the UME tutorial documentation. It covers design, implementation, and best practices for creating effective breadcrumbs that enhance user navigation.

## Purpose of Breadcrumb Navigation

Breadcrumb navigation serves several important purposes in documentation:

1. **Hierarchical Context**: Shows the user's current location within the documentation hierarchy
2. **Navigation Path**: Provides a clear path back to higher-level sections
3. **Orientation**: Helps users understand how content is organized
4. **Efficient Navigation**: Enables quick movement between related sections
5. **Reduced Disorientation**: Prevents users from feeling lost in complex documentation

## Breadcrumb Design

The UME documentation will implement a hierarchical breadcrumb system with the following design:

### Visual Design

```
Home > User Model Enhancements > UME Tutorial > Models > Single Table Inheritance
```

### HTML Structure

```html
<nav aria-label="Breadcrumb" class="breadcrumb">
  <ol>
    <li><a href="/">Home</a></li>
    <li><a href="/100-user-model-enhancements/">User Model Enhancements</a></li>
    <li><a href="/100-user-model-enhancements/031-ume-tutorial/">UME Tutorial</a></li>
    <li><a href="/100-user-model-enhancements/031-ume-tutorial/020-models/">Models</a></li>
    <li aria-current="page">Single Table Inheritance</li>
  </ol>
</nav>
```

### CSS Styling

```css
.breadcrumb {
  padding: 0.75rem 1rem;
  background-color: #f8f9fa;
  border-radius: 0.25rem;
  margin-bottom: 1.5rem;
}

.breadcrumb ol {
  display: flex;
  flex-wrap: wrap;
  padding: 0;
  margin: 0;
  list-style: none;
}

.breadcrumb li {
  display: flex;
  align-items: center;
}

.breadcrumb li + li::before {
  display: inline-block;
  padding: 0 0.5rem;
  color: #6c757d;
  content: ">";
}

.breadcrumb a {
  color: #007bff;
  text-decoration: none;
}

.breadcrumb a:hover {
  text-decoration: underline;
  color: #0056b3;
}

.breadcrumb [aria-current="page"] {
  color: #6c757d;
  font-weight: 500;
}
```

## Breadcrumb Implementation

The breadcrumb navigation will be implemented using the following approach:

### 1. Document Metadata

Each document will include metadata defining its place in the hierarchy:

```yaml
---
title: Single Table Inheritance
breadcrumb:
  - title: Home
    url: /
  - title: User Model Enhancements
    url: /100-user-model-enhancements/
  - title: UME Tutorial
    url: /100-user-model-enhancements/030-ume-tutorial/
  - title: Models
    url: /100-user-model-enhancements/030-ume-tutorial/020-models/
  - title: Single Table Inheritance
    url: /100-user-model-enhancements/030-ume-tutorial/020-models/030-single-table-inheritance.md
---
```

### 2. Automatic Generation

For most documents, breadcrumbs can be automatically generated based on the file path:

1. Parse the file path to determine the hierarchy
2. Map directory names to human-readable titles
3. Generate breadcrumb links based on the hierarchy

### 3. Manual Overrides

Some documents may need custom breadcrumbs that don't match the file structure:

```yaml
---
title: Advanced STI Techniques
breadcrumb_override:
  - title: Home
    url: /
  - title: User Model Enhancements
    url: /100-user-model-enhancements/
  - title: UME Tutorial
    url: /100-user-model-enhancements/030-ume-tutorial/
  - title: Advanced Features
    url: /100-user-model-enhancements/030-ume-tutorial/060-advanced/
  - title: Advanced STI Techniques
    url: /100-user-model-enhancements/030-ume-tutorial/060-advanced/020-advanced-sti.md
---
```

### 4. Breadcrumb Rendering

Breadcrumbs will be rendered at the top of each document, below the header and above the main content.

## Breadcrumb Structure

The UME documentation breadcrumb structure follows the documentation hierarchy:

### Main Documentation Hierarchy

1. **Home**: The documentation home page
2. **User Model Enhancements**: The main section for UME
3. **UME Tutorial**: The UME tutorial section
4. **Topic Section**: The specific topic section (e.g., Models, Authentication)
5. **Specific Topic**: The specific topic page

### Alternative Paths

Some content may have alternative navigation paths:

#### Learning Path Breadcrumbs

```
Home > User Model Enhancements > UME Tutorial > Learning Paths > Beginner Path
```

#### Quick Reference Breadcrumbs

```
Home > User Model Enhancements > UME Tutorial > Quick Reference > User Model
```

#### API Documentation Breadcrumbs

```
Home > User Model Enhancements > UME Tutorial > API > User API
```

## Directory to Title Mapping

The following mapping will be used to convert directory names to human-readable titles:

| Directory | Title |
|-----------|-------|
| `100-user-model-enhancements` | User Model Enhancements |
| `031-ume-tutorial` | UME Tutorial |
| `010-getting-started` | Getting Started |
| `020-models` | Models |
| `030-authentication` | Authentication |
| `040-teams` | Teams |
| `050-real-time` | Real-time Features |
| `060-advanced` | Advanced Features |
| `070-api` | API |
| `080-testing` | Testing |
| `090-deployment` | Deployment |
| `100-examples` | Examples |
| `110-troubleshooting` | Troubleshooting |
| `120-performance` | Performance |
| `130-security` | Security |
| `140-internationalization` | Internationalization |
| `150-accessibility` | Accessibility |
| `160-mobile` | Mobile |
| `170-desktop` | Desktop |
| `180-integrations` | Integrations |
| `190-extensions` | Extensions |
| `200-community` | Community |
| `900-appendices` | Appendices |

## Special Breadcrumb Cases

### Index Pages

Index pages will use the parent directory as the current page:

```
Home > User Model Enhancements > UME Tutorial > Models
```

### Multi-Path Content

Some content may be accessible through multiple paths. In these cases:

1. Use the most logical or common path as the default
2. Provide alternative breadcrumbs through metadata overrides
3. Consider the user's journey when determining the appropriate breadcrumb path

### Deep Nesting

For deeply nested content (more than 5 levels), consider:

1. Truncating the breadcrumb to show only the most relevant levels
2. Using an ellipsis to indicate truncated levels
3. Showing the full breadcrumb on hover or expansion

## Breadcrumb Best Practices

To ensure effective breadcrumb navigation:

### 1. Consistency

- Use consistent breadcrumb structure across all documents
- Ensure breadcrumb titles match actual page titles
- Maintain consistent formatting and styling

### 2. Clarity

- Use clear, concise titles in breadcrumbs
- Avoid abbreviations or jargon
- Ensure breadcrumbs accurately reflect the content hierarchy

### 3. Usability

- Keep breadcrumbs visible at the top of the page
- Ensure breadcrumbs are responsive on mobile devices
- Provide visual distinction between breadcrumb levels

### 4. Accessibility

- Use proper ARIA attributes for screen readers
- Ensure sufficient color contrast
- Provide keyboard navigation support

## Implementation Process

The implementation of breadcrumb navigation will follow these steps:

### 1. Template Updates

1. Update documentation templates to include breadcrumb navigation
2. Add CSS styling for breadcrumbs
3. Implement breadcrumb generation logic

### 2. Metadata Addition

1. Add breadcrumb metadata to all documents
2. Create directory-to-title mapping
3. Implement automatic breadcrumb generation

### 3. Special Case Handling

1. Identify documents requiring custom breadcrumbs
2. Add override metadata to these documents
3. Test special case handling

### 4. Testing and Validation

1. Test breadcrumb navigation on all document types
2. Verify correct hierarchy representation
3. Test on different devices and screen sizes
4. Validate accessibility compliance

## Examples

### Example 1: Standard Page Breadcrumb

For the document `docs/100-user-model-enhancements/031-ume-tutorial/020-models/030-single-table-inheritance.md`:

```html
<nav aria-label="Breadcrumb" class="breadcrumb">
  <ol>
    <li><a href="/">Home</a></li>
    <li><a href="/100-user-model-enhancements/">User Model Enhancements</a></li>
    <li><a href="/100-user-model-enhancements/031-ume-tutorial/">UME Tutorial</a></li>
    <li><a href="/100-user-model-enhancements/031-ume-tutorial/020-models/">Models</a></li>
    <li aria-current="page">Single Table Inheritance</li>
  </ol>
</nav>
```

### Example 2: Index Page Breadcrumb

For the document `docs/100-user-model-enhancements/031-ume-tutorial/020-models/000-index.md`:

```html
<nav aria-label="Breadcrumb" class="breadcrumb">
  <ol>
    <li><a href="/">Home</a></li>
    <li><a href="/100-user-model-enhancements/">User Model Enhancements</a></li>
    <li><a href="/100-user-model-enhancements/031-ume-tutorial/">UME Tutorial</a></li>
    <li aria-current="page">Models</li>
  </ol>
</nav>
```

### Example 3: Learning Path Breadcrumb

For the document `docs/100-user-model-enhancements/031-ume-tutorial/080-learning-paths/010-beginner-learning-path.md`:

```html
<nav aria-label="Breadcrumb" class="breadcrumb">
  <ol>
    <li><a href="/">Home</a></li>
    <li><a href="/100-user-model-enhancements/">User Model Enhancements</a></li>
    <li><a href="/100-user-model-enhancements/031-ume-tutorial/">UME Tutorial</a></li>
    <li><a href="/100-user-model-enhancements/031-ume-tutorial/080-learning-paths/">Learning Paths</a></li>
    <li aria-current="page">Beginner Learning Path</li>
  </ol>
</nav>
```

### Example 4: Custom Breadcrumb

For a document with a custom breadcrumb path:

```html
<nav aria-label="Breadcrumb" class="breadcrumb">
  <ol>
    <li><a href="/">Home</a></li>
    <li><a href="/100-user-model-enhancements/">User Model Enhancements</a></li>
    <li><a href="/100-user-model-enhancements/031-ume-tutorial/">UME Tutorial</a></li>
    <li><a href="/100-user-model-enhancements/031-ume-tutorial/060-advanced/">Advanced Features</a></li>
    <li><a href="/100-user-model-enhancements/031-ume-tutorial/060-advanced/020-advanced-sti.md">Advanced STI Techniques</a></li>
    <li aria-current="page">STI Performance Optimization</li>
  </ol>
</nav>
```

## Mobile Considerations

On mobile devices, breadcrumbs will be adapted for smaller screens:

### Responsive Design

1. **Wrapping**: Allow breadcrumbs to wrap to multiple lines
2. **Truncation**: Consider truncating very long breadcrumb paths
3. **Collapsing**: Potentially collapse middle sections on very small screens

### Mobile-Specific CSS

```css
@media (max-width: 768px) {
  .breadcrumb {
    padding: 0.5rem;
    margin-bottom: 1rem;
  }
  
  .breadcrumb li {
    font-size: 0.875rem;
  }
}

@media (max-width: 480px) {
  .breadcrumb li:not(:first-child):not(:last-child):not(:nth-last-child(2)) {
    display: none;
  }
  
  .breadcrumb li:nth-last-child(3)::before {
    content: "...";
  }
}
```

## Integration with Other Navigation

Breadcrumb navigation will be integrated with other navigation elements:

### 1. Main Navigation

Breadcrumbs complement the main navigation by showing the current location within the hierarchy.

### 2. Table of Contents

Breadcrumbs work alongside the table of contents, which shows the structure within the current document.

### 3. "See Also" Sections

Breadcrumbs provide hierarchical navigation, while "See Also" sections provide conceptual navigation.

### 4. Search

Breadcrumbs help users understand the context of search results.

## Maintenance Guidelines

To maintain effective breadcrumb navigation:

1. **Update with Content Changes**: When content is moved or restructured, update breadcrumbs
2. **Verify Links**: Regularly check breadcrumb links for accuracy
3. **Review Titles**: Ensure breadcrumb titles remain clear and consistent
4. **Check Custom Breadcrumbs**: Review custom breadcrumb overrides for continued relevance
5. **Monitor Usage**: Use analytics to understand how users interact with breadcrumbs

## Conclusion

Implementing breadcrumb navigation throughout the UME documentation will significantly enhance user orientation and navigation. By following these guidelines, the documentation will provide clear hierarchical context and efficient navigation paths for users.

## See Also

- [Cross-Reference Audit](010-cross-reference-audit.md) - Review of the current cross-referencing system
- [Improved Cross-Reference System](020-improved-cross-reference-system.md) - Standards for cross-references
- [Concept Relationship Map](030-concept-relationship-map.md) - Visual map of concept relationships
- ["See Also" Sections Implementation](040-see-also-sections.md) - Guidelines for implementing "See Also" sections
- [Tagging System](050-tagging-system.md) - Tagging system for related concepts
