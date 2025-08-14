# Citation System for External References

<link rel="stylesheet" href="../assets/css/styles.css">

This document provides comprehensive guidance for implementing a citation system for external references throughout the UME tutorial documentation. It covers design, implementation strategies, and best practices for creating effective citations that enhance the credibility and usefulness of the documentation.

## Purpose of a Citation System

A citation system for external references serves several important purposes in documentation:

1. **Credibility**: Enhances the credibility of the documentation by citing authoritative sources
2. **Attribution**: Properly attributes ideas, concepts, and code to their original sources
3. **Further Reading**: Provides users with resources for deeper exploration
4. **Verification**: Allows users to verify information from primary sources
5. **Academic Rigor**: Demonstrates a commitment to academic rigor and intellectual honesty

## Types of Citations

The UME documentation will implement several types of citations:

### 1. In-text Citations

Brief citations within the text:

```html
<p>Single Table Inheritance is a pattern described by Martin Fowler<sup><a href="#citation-1" class="citation-ref">1</a></sup> that allows multiple model classes to share a single database table.</p>
```

### 2. Footnote Citations

Citations listed as footnotes at the bottom of the page:

```html
<section class="footnotes">
  <hr>
  <ol>
    <li id="citation-1">Fowler, M. (2002). <em>Patterns of Enterprise Application Architecture</em>. Addison-Wesley. <a href="https://martinfowler.com/eaaCatalog/singleTableInheritance.html" target="_blank">https://martinfowler.com/eaaCatalog/singleTableInheritance.html</a></li>
    <li id="citation-2">Otwell, T. (2023). <em>Laravel Documentation: Eloquent: Relationships</em>. Laravel. <a href="https://laravel.com/docs/10.x/eloquent-relationships" target="_blank">https://laravel.com/docs/10.x/eloquent-relationships</a></li>
  </ol>
</section>
```

### 3. Bibliography Section

A comprehensive bibliography at the end of the documentation:

```html
<section class="bibliography">
  <h2>Bibliography</h2>
  <ul class="bibliography-list">
    <li id="bib-fowler-2002">
      <span class="bib-author">Fowler, M.</span>
      <span class="bib-year">(2002).</span>
      <span class="bib-title">Patterns of Enterprise Application Architecture.</span>
      <span class="bib-publisher">Addison-Wesley.</span>
      <span class="bib-url"><a href="https://martinfowler.com/eaaCatalog/singleTableInheritance.html" target="_blank">https://martinfowler.com/eaaCatalog/singleTableInheritance.html</a></span>
    </li>
    <li id="bib-otwell-2023">
      <span class="bib-author">Otwell, T.</span>
      <span class="bib-year">(2023).</span>
      <span class="bib-title">Laravel Documentation: Eloquent: Relationships.</span>
      <span class="bib-publisher">Laravel.</span>
      <span class="bib-url"><a href="https://laravel.com/docs/10.x/eloquent-relationships" target="_blank">https://laravel.com/docs/10.x/eloquent-relationships</a></span>
    </li>
  </ul>
</section>
```

### 4. Code Attribution Comments

Comments in code examples attributing the source:

```php
/**
 * Implementation based on Taylor Otwell's example in Laravel 010-consolidated-starter-kits
 * @see https://laravel.com/docs/10.x/eloquent-relationships#one-to-many
 */
public function posts()
{
    return $this->hasMany(Post::class);
}
```

### 5. External Link Callouts

Callouts highlighting important external resources:

```html
<div class="callout reference">
  <h4>External Resource: Laravel Documentation</h4>
  <p>For more information about Eloquent relationships, see the <a href="https://laravel.com/docs/10.x/eloquent-relationships" target="_blank">official Laravel documentation</a>.</p>
</div>
```

## Citation Design

### Visual Design Principles

1. **Unobtrusiveness**: Citations should not disrupt the reading flow
2. **Clarity**: Clear visual indicators for citations
3. **Consistency**: Consistent styling across all citations
4. **Accessibility**: Accessible design for all users
5. **Usability**: Easy navigation between citations and references

### CSS Styling

#### In-text Citations

```css
.citation-ref {
  font-size: 0.75em;
  vertical-align: super;
  line-height: 0;
  color: #007bff;
  text-decoration: none;
}

.citation-ref:hover {
  text-decoration: underline;
}
```

#### Footnotes Section

```css
.footnotes {
  margin-top: 3rem;
  padding-top: 1.5rem;
  border-top: 1px solid #dee2e6;
  font-size: 0.875rem;
}

.footnotes hr {
  display: none;
}

.footnotes ol {
  padding-left: 1.5rem;
}

.footnotes li {
  margin-bottom: 0.75rem;
}

.footnotes a {
  color: #007bff;
  word-break: break-all;
}
```

#### Bibliography Section

```css
.bibliography {
  margin-top: 3rem;
  padding-top: 1.5rem;
  border-top: 1px solid #dee2e6;
}

.bibliography-list {
  list-style-type: none;
  padding-left: 0;
}

.bibliography-list li {
  margin-bottom: 1.25rem;
  padding-left: 2rem;
  text-indent: -2rem;
}

.bib-author {
  font-weight: 600;
}

.bib-year {
  margin-right: 0.5rem;
}

.bib-title {
  font-style: italic;
}

.bib-publisher {
  margin-left: 0.5rem;
}

.bib-url {
  display: block;
  margin-top: 0.25rem;
  word-break: break-all;
}
```

#### Reference Callout

```css
.callout.reference {
  background-color: #e9ecef;
  border-left: 4px solid #6c757d;
  padding: 1.25rem;
  margin: 1.5rem 0;
  border-radius: 0 0.25rem 0.25rem 0;
}

.callout.reference h4 {
  margin-top: 0;
  color: #495057;
}

.callout.reference p:last-child {
  margin-bottom: 0;
}

.callout.reference a {
  color: #007bff;
  text-decoration: none;
}

.callout.reference a:hover {
  text-decoration: underline;
}
```

## Citation Formats

The UME documentation will use consistent citation formats based on the APA (American Psychological Association) style:

### 1. Books

```
Author, A. A. (Year). Title of book. Publisher.
```

Example:
```
Fowler, M. (2002). Patterns of Enterprise Application Architecture. Addison-Wesley.
```

### 2. Online Documentation

```
Author, A. A. (Year). Title of documentation. Publisher. URL
```

Example:
```
Otwell, T. (2023). Laravel Documentation: Eloquent: Relationships. Laravel. https://laravel.com/docs/10.x/eloquent-relationships
```

### 3. Journal Articles

```
Author, A. A. (Year). Title of article. Title of Journal, Volume(Issue), Page range. DOI or URL
```

Example:
```
Smith, J. (2020). Modern approaches to Single Table Inheritance in PHP. Journal of Web Development, 15(3), 45-62. https://doi.org/10.1234/jwd.2020.15.3.45
```

### 4. Blog Posts

```
Author, A. A. (Year, Month Day). Title of post. Blog Name. URL
```

Example:
```
Johnson, R. (2022, March 15). Optimizing Laravel Models with Single Table Inheritance. Laravel News. https://laravel-news.com/optimizing-models-with-sti
```

### 5. GitHub Repositories

```
Author, A. A. (Year). Repository name [GitHub repository]. GitHub. URL
```

Example:
```
Spatie. (2023). laravel-permission [GitHub repository]. GitHub. https://github.com/spatie/laravel-permission
```

## Implementation Strategy

### 1. Citation Management

For managing citations:

#### Centralized Citation Database

Create a centralized citation database in YAML format:

```yaml
# citations.yaml
citations:
  fowler-2002:
    type: book
    author: Fowler, M.
    year: 2002
    title: Patterns of Enterprise Application Architecture
    publisher: Addison-Wesley
    url: https://martinfowler.com/eaaCatalog/singleTableInheritance.html
    
  otwell-2023:
    type: 010-consolidated-starter-kits
    author: Otwell, T.
    year: 2023
    title: "Laravel Documentation: Eloquent: Relationships"
    publisher: Laravel
    url: https://laravel.com/docs/10.x/eloquent-relationships
    
  spatie-2023:
    type: repository
    author: Spatie
    year: 2023
    title: 100-laravel-permission
    publisher: GitHub
    url: https://github.com/spatie/laravel-permission
```

#### Implementation Process

1. Create a centralized citation database
2. Add all external references to the database
3. Create templates for rendering citations
4. Implement citation rendering in documentation build process

### 2. In-document Citations

For implementing citations within documents:

#### Metadata Approach

Include citation metadata in document frontmatter:

```yaml
---
title: Single Table Inheritance
citations:
  - id: fowler-2002
    context: Definition of Single Table Inheritance pattern
  - id: otwell-2023
    context: Implementation of model relationships in Laravel
---
```

#### Implementation Process

1. Define citations for each document
2. Add citation metadata to document frontmatter
3. Create templates for rendering in-text citations and footnotes
4. Implement citation rendering in documentation build process

### 3. Bibliography Generation

For generating a comprehensive bibliography:

#### Automated Approach

1. Collect all citations from all documents
2. Remove duplicates
3. Sort by author and year
4. Generate bibliography in appropriate format
5. Add to appendix or dedicated bibliography page

## Examples

### Example 1: In-text Citation with Footnote

```html
<p>Single Table Inheritance is a pattern described by Martin Fowler<sup><a href="#citation-1" class="citation-ref">1</a></sup> that allows multiple model classes to share a single database table. This approach is particularly useful in Laravel applications where you want to maintain a clean object hierarchy while simplifying database structure.</p>

<p>Laravel's Eloquent ORM provides excellent support for implementing this pattern through its powerful relationship features<sup><a href="#citation-2" class="citation-ref">2</a></sup>.</p>

<!-- Later in the document -->
<section class="footnotes">
  <hr>
  <ol>
    <li id="citation-1">Fowler, M. (2002). <em>Patterns of Enterprise Application Architecture</em>. Addison-Wesley. <a href="https://martinfowler.com/eaaCatalog/singleTableInheritance.html" target="_blank">https://martinfowler.com/eaaCatalog/singleTableInheritance.html</a></li>
    <li id="citation-2">Otwell, T. (2023). <em>Laravel Documentation: Eloquent: Relationships</em>. Laravel. <a href="https://laravel.com/docs/10.x/eloquent-relationships" target="_blank">https://laravel.com/docs/10.x/eloquent-relationships</a></li>
  </ol>
</section>
```

### Example 2: Code Attribution

```php
/**
 * Implementation based on Spatie's laravel-permission package
 * @see https://github.com/spatie/laravel-permission
 * @citation spatie-2023
 */
public function roles()
{
    return $this->belongsToMany(
        config('permission.models.role'),
        config('permission.table_names.model_has_roles'),
        'model_id',
        'role_id'
    );
}
```

### Example 3: External Resource Callout

```html
<div class="callout reference">
  <h4>External Resource: Laravel Documentation</h4>
  <p>For comprehensive information about Laravel's authentication system, see the <a href="https://laravel.com/docs/10.x/authentication" target="_blank">official Laravel authentication documentation</a>.</p>
  <p><small>Otwell, T. (2023). Laravel Documentation: Authentication. Laravel.</small></p>
</div>
```

### Example 4: Bibliography Section

```html
<section class="bibliography">
  <h2>Bibliography</h2>
  <ul class="bibliography-list">
    <li id="bib-fowler-2002">
      <span class="bib-author">Fowler, M.</span>
      <span class="bib-year">(2002).</span>
      <span class="bib-title">Patterns of Enterprise Application Architecture.</span>
      <span class="bib-publisher">Addison-Wesley.</span>
      <span class="bib-url"><a href="https://martinfowler.com/eaaCatalog/singleTableInheritance.html" target="_blank">https://martinfowler.com/eaaCatalog/singleTableInheritance.html</a></span>
    </li>
    <li id="bib-otwell-2023a">
      <span class="bib-author">Otwell, T.</span>
      <span class="bib-year">(2023).</span>
      <span class="bib-title">Laravel Documentation: Eloquent: Relationships.</span>
      <span class="bib-publisher">Laravel.</span>
      <span class="bib-url"><a href="https://laravel.com/docs/10.x/eloquent-relationships" target="_blank">https://laravel.com/docs/10.x/eloquent-relationships</a></span>
    </li>
    <li id="bib-otwell-2023b">
      <span class="bib-author">Otwell, T.</span>
      <span class="bib-year">(2023).</span>
      <span class="bib-title">Laravel Documentation: Authentication.</span>
      <span class="bib-publisher">Laravel.</span>
      <span class="bib-url"><a href="https://laravel.com/docs/10.x/authentication" target="_blank">https://laravel.com/docs/10.x/authentication</a></span>
    </li>
    <li id="bib-spatie-2023">
      <span class="bib-author">Spatie.</span>
      <span class="bib-year">(2023).</span>
      <span class="bib-title">laravel-permission [GitHub repository].</span>
      <span class="bib-publisher">GitHub.</span>
      <span class="bib-url"><a href="https://github.com/spatie/laravel-permission" target="_blank">https://github.com/spatie/laravel-permission</a></span>
    </li>
  </ul>
</section>
```

## Citation Categories

Different types of external references serve different purposes:

### 1. Conceptual References

References to foundational concepts and patterns:

```html
<p>The Single Table Inheritance pattern<sup><a href="#citation-1" class="citation-ref">1</a></sup> provides a way to represent an inheritance hierarchy in a relational database.</p>
```

### 2. Implementation References

References to specific implementation approaches:

```html
<p>Laravel's implementation of model factories<sup><a href="#citation-2" class="citation-ref">2</a></sup> provides a convenient way to generate test data for your models.</p>
```

### 3. Package References

References to third-party packages:

```html
<p>The Spatie Laravel Permission package<sup><a href="#citation-3" class="citation-ref">3</a></sup> offers a comprehensive solution for role-based permissions in Laravel applications.</p>
```

### 4. Best Practice References

References to best practices and standards:

```html
<p>Following the PSR-12 coding standard<sup><a href="#citation-4" class="citation-ref">4</a></sup> ensures consistent code formatting across your Laravel application.</p>
```

## Mobile Considerations

On mobile devices, citations should be adapted:

### Responsive Design

1. **In-text Citations**: Maintain but ensure tap targets are large enough
2. **Footnotes**: Adjust spacing for better readability
3. **Bibliography**: Adjust formatting for smaller screens

### Mobile-Specific CSS

```css
@media (max-width: 768px) {
  .citation-ref {
    padding: 0 0.25rem;
  }
  
  .footnotes {
    margin-top: 2rem;
    padding-top: 1rem;
  }
  
  .bibliography-list li {
    padding-left: 1rem;
    text-indent: -1rem;
  }
}
```

## Implementation Process

The implementation of the citation system will follow these steps:

### 1. Citation Database Creation

1. Identify all external references in the documentation
2. Create a centralized citation database
3. Format citations according to APA style
4. Validate all URLs and references

### 2. Template Updates

1. Update documentation templates to include citation elements
2. Add CSS styling for citations
3. Implement citation rendering logic

### 3. Document Updates

1. Add citation metadata to document frontmatter
2. Add in-text citations at appropriate points
3. Add code attribution comments
4. Add external resource callouts

### 4. Bibliography Generation

1. Implement bibliography generation logic
2. Create bibliography page in appendix
3. Add links to bibliography from relevant sections

### 5. Testing and Validation

1. Verify all citations are correctly formatted
2. Check all links to ensure they work
3. Validate accessibility compliance
4. Test on different devices and screen sizes

## Maintenance Guidelines

To maintain an effective citation system:

1. **Regular Updates**: Update citations when referenced resources change
2. **URL Verification**: Regularly check URLs to ensure they still work
3. **New References**: Add new references as they become relevant
4. **Citation Consistency**: Ensure consistent formatting across all citations
5. **Bibliography Updates**: Keep the bibliography up to date with all citations

## Integration with Other Documentation Elements

The citation system works alongside other documentation elements:

### 1. "See Also" Sections

"See Also" sections provide internal references, while citations provide external references.

### 2. External Links

Regular external links provide general resources, while citations provide specific, credible references with proper attribution.

### 3. Code Examples

Code attribution comments provide proper attribution for code examples.

### 4. Appendices

The bibliography can be included as an appendix or linked from appendices.

## Conclusion

Implementing a citation system for external references throughout the UME documentation will significantly enhance its credibility, provide proper attribution, and offer users valuable resources for further exploration. By following these guidelines, the documentation will demonstrate a commitment to academic rigor and intellectual honesty while providing a more valuable resource for users.

## See Also

- [Cross-Reference Audit](010-cross-reference-audit.md) - Review of the current cross-referencing system
- [Improved Cross-Reference System](020-improved-cross-reference-system.md) - Standards for cross-references
- [Concept Relationship Map](030-concept-relationship-map.md) - Visual map of concept relationships
- ["See Also" Sections Implementation](040-see-also-sections.md) - Guidelines for implementing "See Also" sections
- [Tagging System](050-tagging-system.md) - Tagging system for related concepts
- [Breadcrumb Navigation](060-breadcrumb-navigation.md) - Implementation of breadcrumb navigation
- [Contextual Navigation](070-contextual-navigation.md) - Implementation of contextual navigation
- [Related Content Suggestions](080-related-content-suggestions.md) - Implementation of related content suggestions
- [Prerequisite and Follow-up Links](090-prerequisite-followup-links.md) - Implementation of prerequisite and follow-up links
