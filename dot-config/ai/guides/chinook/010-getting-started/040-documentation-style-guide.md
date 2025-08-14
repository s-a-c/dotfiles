# Chinook Documentation Style Guide

**Version:** 1.0  
**Created:** 2025-07-16  
**Last Updated:** 2025-07-16  
**Scope:** All Chinook project documentation

## Table of Contents

1. [Overview](#1-overview)
2. [File Naming Conventions](#2-file-naming-conventions)
3. [Document Structure](#3-document-structure)
4. [Content Standards](#4-content-standards)
5. [Code Examples](#5-code-examples)
6. [Accessibility Requirements](#6-accessibility-requirements)
7. [Navigation Standards](#7-navigation-standards)
8. [Quality Assurance](#8-quality-assurance)

## 1. Overview

This style guide establishes consistent formatting, structure, and quality standards for all Chinook project documentation. All documentation must follow these standards to ensure accessibility, maintainability, and professional presentation.

### 1.1 Core Principles

- **Accessibility First:** WCAG 2.1 AA compliance mandatory
- **Educational Focus:** Clear, practical examples for learning
- **Consistency:** Uniform formatting across all documents
- **Maintainability:** Structured for easy updates and validation

### 1.2 Target Audience

- Laravel developers (intermediate level)
- Students learning web development
- Technical documentation maintainers

## 2. File Naming Conventions

### 2.1 Naming Pattern

```
{priority}-{topic}-{type}.md
```

**Examples:**
- `000-chinook-index.md` (main index)
- `010-models-guide.md` (implementation guide)
- `100-resource-testing.md` (testing documentation)

### 2.2 Priority Numbering

- **000-099:** Core documentation and indexes
- **100-199:** Implementation guides
- **200-299:** Advanced features
- **300-399:** Specialized topics

### 2.3 Directory Structure

```
.ai/guides/chinook/
├── 000-*.md (core docs)
├── filament/ (Filament-specific)
├── frontend/ (frontend guides)
├── packages/ (package documentation)
├── testing/ (testing guides)
└── performance/ (performance docs)
```

## 3. Document Structure

### 3.1 Required Header

```markdown
# Document Title

**Version:** X.Y  
**Created:** YYYY-MM-DD  
**Last Updated:** YYYY-MM-DD  
**Scope:** Brief description

## Table of Contents

1. [Section One](#1-section-one)
2. [Section Two](#2-section-two)
...
```

### 3.2 Section Numbering

- Use numbered sections: `## 1. Section Name`
- Use numbered subsections: `### 1.1 Subsection Name`
- Maximum depth: 3 levels (1.1.1)

### 3.3 Required Footer

```markdown
---

## Navigation

- **Previous:** [Previous Document](./previous-doc.md)
- **Next:** [Next Document](./next-doc.md)
- **Index:** [Chinook Documentation Index](./000-chinook-index.md)

## Related Documentation

- [Related Doc 1](./related-doc-1.md)
- [Related Doc 2](./related-doc-2.md)

---

**Last Updated:** YYYY-MM-DD  
**Maintainer:** Technical Documentation Team  
**Source:** [GitHub Repository](https://github.com/s-a-c/chinook)
```

## 4. Content Standards

### 4.1 Writing Style

- **Tone:** Professional, educational, clear
- **Voice:** Active voice preferred
- **Tense:** Present tense for instructions
- **Person:** Second person ("you") for instructions

### 4.2 Formatting Standards

- **Bold:** Use for emphasis and UI elements
- **Italic:** Use for file names and variables
- **Code:** Use backticks for inline code
- **Lists:** Use numbered lists for procedures, bullet lists for features

### 4.3 Link Standards

- **Internal Links:** Use relative paths
- **External Links:** Include full URLs
- **GitHub Links:** Always include source attribution
- **Anchor Links:** Use lowercase with hyphens

## 5. Code Examples

### 5.1 Code Block Standards

```php
<?php

namespace App\Models\Chinook;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

/**
 * Chinook Artist Model
 * 
 * Represents musical artists in the Chinook database.
 * Educational example for Laravel model implementation.
 */
class Artist extends Model
{
    /**
     * The table associated with the model.
     */
    protected $table = 'chinook_artists';

    /**
     * The attributes that are mass assignable.
     */
    protected $fillable = [
        'name',
    ];

    /**
     * Get the albums for the artist.
     */
    public function albums(): HasMany
    {
        return $this->hasMany(Album::class);
    }
}
```

### 5.2 Code Example Requirements

- **Complete Examples:** Always provide working, complete code
- **Comments:** Include educational comments
- **Error Handling:** Show proper error handling patterns
- **Namespace:** Use `App\Models\Chinook` namespace
- **Table Prefix:** Use `chinook_` prefix for all tables

### 5.3 Syntax Highlighting

- **PHP:** `php`
- **Blade:** `blade`
- **JavaScript:** `javascript`
- **JSON:** `json`
- **Shell:** `bash`
- **SQL:** `sql`

## 6. Accessibility Requirements

### 6.1 WCAG 2.1 AA Compliance

- **Alt Text:** All images must have descriptive alt text
- **Headings:** Proper heading hierarchy (no skipping levels)
- **Links:** Descriptive link text (no "click here")
- **Color:** Information not conveyed by color alone
- **Contrast:** Minimum 4.5:1 contrast ratio

### 6.2 Screen Reader Support

- **Tables:** Use proper table headers
- **Lists:** Use semantic list markup
- **Code:** Provide context for code examples
- **Navigation:** Clear navigation structure

### 6.3 Keyboard Navigation

- **Links:** All links must be keyboard accessible
- **Focus:** Clear focus indicators
- **Skip Links:** Provide skip navigation where needed

## 7. Navigation Standards

### 7.1 Table of Contents

- **Required:** All documents must have TOC
- **Format:** Numbered list with anchor links
- **Depth:** Maximum 3 levels shown
- **Position:** After document header

### 7.2 Navigation Footer

- **Required:** All documents must have navigation footer
- **Elements:** Previous, Next, Index, Related
- **Format:** Consistent across all documents

### 7.3 Cross-References

- **Internal:** Use relative paths
- **Context:** Provide context for links
- **Validation:** All links must be validated

## 8. Quality Assurance

### 8.1 Review Checklist

- [ ] Document follows naming conventions
- [ ] Header includes all required elements
- [ ] TOC is complete and accurate
- [ ] All code examples are tested
- [ ] Links are validated
- [ ] Accessibility requirements met
- [ ] Navigation footer is complete
- [ ] Spelling and grammar checked

### 8.2 Validation Tools

- **Link Validation:** Automated link checking
- **Accessibility:** WCAG validation tools
- **Spelling:** Automated spell checking
- **Code:** Syntax validation for examples

### 8.3 Maintenance Schedule

- **Monthly:** Link validation
- **Quarterly:** Content review
- **Annually:** Style guide updates

---

**Last Updated:** 2025-07-16
**Maintainer:** Technical Documentation Team
**Source:** [GitHub Repository](https://github.com/s-a-c/chinook)

<<<<<<
[Back](030-educational-scope.md) | [Forward](../020-database/000-index.md)
[Top](#documentation-style-guide)
<<<<<<
