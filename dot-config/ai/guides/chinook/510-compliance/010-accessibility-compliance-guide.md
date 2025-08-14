# Accessibility Compliance Guide

**Version:** 1.0  
**Created:** 2025-07-16  
**Last Updated:** 2025-07-16  
**Scope:** WCAG 2.1 AA compliance implementation for Chinook project

## Table of Contents

1. [Overview](#1-overview)
2. [WCAG 2.1 AA Requirements](#2-wcag-21-aa-requirements)
3. [Implementation Standards](#3-implementation-standards)
4. [Code Examples](#4-code-examples)
5. [Testing and Validation](#5-testing-and-validation)
6. [Compliance Checklist](#6-compliance-checklist)

## 1. Overview

This guide ensures the Chinook project meets WCAG 2.1 AA accessibility standards, providing equal access to all users regardless of their abilities or assistive technologies used.

### 1.1 Accessibility Principles

- **Perceivable:** Information must be presentable in ways users can perceive
- **Operable:** Interface components must be operable by all users
- **Understandable:** Information and UI operation must be understandable
- **Robust:** Content must be robust enough for various assistive technologies

### 1.2 Compliance Scope

- **Filament Admin Panel:** All administrative interfaces
- **Frontend Views:** Public-facing pages and components
- **Documentation:** All markdown files and generated content
- **API Responses:** JSON structure and error messages

## 2. WCAG 2.1 AA Requirements

### 2.1 Perceivable Requirements

```html
<!-- Color and Contrast Standards -->
<style>
/* Minimum contrast ratios for WCAG 2.1 AA */
:root {
    /* Text colors with 4.5:1 contrast ratio minimum */
    --text-primary: #1a1a1a;      /* 15.3:1 on white */
    --text-secondary: #4a4a4a;    /* 9.7:1 on white */
    --text-muted: #6b6b6b;        /* 6.4:1 on white */
    
    /* Background colors */
    --bg-primary: #ffffff;
    --bg-secondary: #f8f9fa;
    --bg-accent: #e9ecef;
    
    /* Interactive element colors */
    --link-color: #0066cc;         /* 7.0:1 on white */
    --link-hover: #004499;         /* 10.7:1 on white */
    --focus-outline: #005fcc;      /* High contrast focus */
    
    /* Status colors with sufficient contrast */
    --success: #0f5132;            /* 9.6:1 on white */
    --warning: #664d03;            /* 8.9:1 on white */
    --error: #842029;              /* 8.2:1 on white */
    --info: #055160;               /* 9.4:1 on white */
}

/* Focus indicators for keyboard navigation */
*:focus {
    outline: 2px solid var(--focus-outline);
    outline-offset: 2px;
}

/* Skip links for screen readers */
.skip-link {
    position: absolute;
    top: -40px;
    left: 6px;
    background: var(--text-primary);
    color: var(--bg-primary);
    padding: 8px;
    text-decoration: none;
    z-index: 1000;
}

.skip-link:focus {
    top: 6px;
}
</style>

<!-- Image accessibility -->
<img src="artist-photo.jpg" 
     alt="Portrait of John Doe performing on stage with guitar" 
     loading="lazy">

<!-- Decorative images -->
<img src="decorative-border.svg" 
     alt="" 
     role="presentation">

<!-- Complex images with descriptions -->
<figure>
    <img src="sales-chart.png" 
         alt="Bar chart showing monthly sales data">
    <figcaption>
        Monthly sales from January to December 2024. 
        Peak sales occurred in December with 1,200 units sold.
        <a href="#sales-data-table">View detailed sales data</a>
    </figcaption>
</figure>
```

### 2.2 Operable Requirements

```html
<!-- Keyboard navigation support -->
<nav aria-label="Main navigation">
    <ul role="menubar">
        <li role="none">
            <a href="/" role="menuitem" tabindex="0">Home</a>
        </li>
        <li role="none">
            <button role="menuitem" 
                    aria-expanded="false" 
                    aria-haspopup="true"
                    tabindex="0">
                Artists
            </button>
            <ul role="menu" aria-label="Artists submenu">
                <li role="none">
                    <a href="/artists" role="menuitem" tabindex="-1">All Artists</a>
                </li>
                <li role="none">
                    <a href="/artists/popular" role="menuitem" tabindex="-1">Popular</a>
                </li>
            </ul>
        </li>
    </ul>
</nav>

<!-- Form accessibility -->
<form>
    <fieldset>
        <legend>Artist Information</legend>
        
        <div class="form-group">
            <label for="artist-name">
                Artist Name
                <span aria-label="required" class="required">*</span>
            </label>
            <input type="text" 
                   id="artist-name" 
                   name="name" 
                   required 
                   aria-describedby="name-help name-error"
                   autocomplete="name">
            <div id="name-help" class="help-text">
                Enter the full name of the artist or band
            </div>
            <div id="name-error" class="error-text" aria-live="polite">
                <!-- Error messages appear here -->
            </div>
        </div>
        
        <div class="form-group">
            <label for="artist-bio">Biography</label>
            <textarea id="artist-bio" 
                      name="bio" 
                      rows="4" 
                      aria-describedby="bio-help"
                      maxlength="1000"></textarea>
            <div id="bio-help" class="help-text">
                Brief description of the artist (maximum 1000 characters)
            </div>
        </div>
    </fieldset>
    
    <button type="submit" aria-describedby="submit-help">
        Save Artist
    </button>
    <div id="submit-help" class="help-text">
        Press Enter or click to save the artist information
    </div>
</form>
```

### 2.3 Understandable Requirements

```html
<!-- Page structure and headings -->
<!DOCTYPE html>
<html lang="en">
<head>
    <title>Artist Management - Chinook Music Database</title>
    <meta name="description" content="Manage artists in the Chinook music database">
</head>
<body>
    <header>
        <h1>Chinook Music Database</h1>
        <nav aria-label="Main navigation">
            <!-- Navigation content -->
        </nav>
    </header>
    
    <main>
        <h2>Artist Management</h2>
        
        <section aria-labelledby="artist-list-heading">
            <h3 id="artist-list-heading">All Artists</h3>
            <!-- Artist list content -->
        </section>
        
        <section aria-labelledby="add-artist-heading">
            <h3 id="add-artist-heading">Add New Artist</h3>
            <!-- Add artist form -->
        </section>
    </main>
    
    <footer>
        <p>© 2025 Chinook Music Database - Educational Use Only</p>
    </footer>
</body>
</html>

<!-- Data tables with proper headers -->
<table>
    <caption>Artist List with Album Counts</caption>
    <thead>
        <tr>
            <th scope="col">Artist Name</th>
            <th scope="col">Country</th>
            <th scope="col">Albums</th>
            <th scope="col">Actions</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <th scope="row">The Beatles</th>
            <td>United Kingdom</td>
            <td>13</td>
            <td>
                <a href="/artists/the-beatles" aria-label="View The Beatles details">
                    View
                </a>
                <a href="/artists/the-beatles/edit" aria-label="Edit The Beatles information">
                    Edit
                </a>
            </td>
        </tr>
    </tbody>
</table>
```

## 3. Implementation Standards

### 3.1 Laravel Blade Component Accessibility

```php
<?php
// resources/views/components/accessible-form-input.blade.php

@props([
    'label',
    'name',
    'type' => 'text',
    'required' => false,
    'help' => null,
    'error' => null,
])

<div class="form-group">
    <label for="{{ $name }}" class="form-label">
        {{ $label }}
        @if($required)
            <span aria-label="required" class="required">*</span>
        @endif
    </label>
    
    <input 
        type="{{ $type }}"
        id="{{ $name }}"
        name="{{ $name }}"
        {{ $required ? 'required' : '' }}
        @if($help || $error)
            aria-describedby="@if($help){{ $name }}-help @endif @if($error){{ $name }}-error @endif"
        @endif
        {{ $attributes->merge(['class' => 'form-control']) }}
    >
    
    @if($help)
        <div id="{{ $name }}-help" class="help-text">
            {{ $help }}
        </div>
    @endif
    
    @if($error)
        <div id="{{ $name }}-error" class="error-text" aria-live="polite">
            {{ $error }}
        </div>
    @endif
</div>
```

### 3.2 Filament Resource Accessibility

```php
<?php

namespace App\Filament\Resources;

use Filament\Forms;
use Filament\Tables;
use Filament\Resources\Resource;

class ArtistResource extends Resource
{
    public static function form(Form $form): Form
    {
        return $form->schema([
            Forms\Components\TextInput::make('name')
                ->label('Artist Name')
                ->required()
                ->maxLength(255)
                ->helperText('Enter the full name of the artist or band')
                ->placeholder('e.g., The Beatles')
                ->autocomplete('name'),
                
            Forms\Components\Textarea::make('bio')
                ->label('Biography')
                ->maxLength(1000)
                ->helperText('Brief description of the artist (maximum 1000 characters)')
                ->rows(4),
                
            Forms\Components\Select::make('country')
                ->label('Country')
                ->options([
                    'US' => 'United States',
                    'UK' => 'United Kingdom',
                    'CA' => 'Canada',
                    // ... other countries
                ])
                ->searchable()
                ->helperText('Select the artist\'s country of origin'),
                
            Forms\Components\Toggle::make('is_active')
                ->label('Active Status')
                ->helperText('Toggle to activate or deactivate this artist')
                ->default(true),
        ]);
    }
    
    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('name')
                    ->label('Artist Name')
                    ->searchable()
                    ->sortable()
                    ->description(fn($record) => $record->country),
                    
                Tables\Columns\TextColumn::make('albums_count')
                    ->label('Albums')
                    ->counts('albums')
                    ->sortable(),
                    
                Tables\Columns\IconColumn::make('is_active')
                    ->label('Status')
                    ->boolean()
                    ->trueIcon('heroicon-o-check-circle')
                    ->falseIcon('heroicon-o-x-circle'),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('country')
                    ->label('Country')
                    ->options([
                        'US' => 'United States',
                        'UK' => 'United Kingdom',
                        'CA' => 'Canada',
                    ]),
                    
                Tables\Filters\TernaryFilter::make('is_active')
                    ->label('Active Status')
                    ->placeholder('All artists')
                    ->trueLabel('Active only')
                    ->falseLabel('Inactive only'),
            ])
            ->actions([
                Tables\Actions\ViewAction::make()
                    ->label('View Details'),
                Tables\Actions\EditAction::make()
                    ->label('Edit Artist'),
                Tables\Actions\DeleteAction::make()
                    ->label('Delete Artist')
                    ->requiresConfirmation(),
            ]);
    }
}
```

## 4. Code Examples

### 4.1 Accessible JavaScript Components

```javascript
// Accessible modal component
class AccessibleModal {
    constructor(modalElement) {
        this.modal = modalElement;
        this.trigger = document.querySelector(`[data-modal="${modalElement.id}"]`);
        this.closeButton = modalElement.querySelector('[data-modal-close]');
        this.focusableElements = modalElement.querySelectorAll(
            'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
        );
        this.firstFocusable = this.focusableElements[0];
        this.lastFocusable = this.focusableElements[this.focusableElements.length - 1];
        
        this.init();
    }
    
    init() {
        this.trigger?.addEventListener('click', () => this.open());
        this.closeButton?.addEventListener('click', () => this.close());
        this.modal.addEventListener('keydown', (e) => this.handleKeydown(e));
        
        // Close on backdrop click
        this.modal.addEventListener('click', (e) => {
            if (e.target === this.modal) this.close();
        });
    }
    
    open() {
        this.modal.style.display = 'block';
        this.modal.setAttribute('aria-hidden', 'false');
        
        // Trap focus in modal
        this.firstFocusable?.focus();
        
        // Prevent body scroll
        document.body.style.overflow = 'hidden';
        
        // Announce to screen readers
        this.modal.setAttribute('aria-live', 'polite');
    }
    
    close() {
        this.modal.style.display = 'none';
        this.modal.setAttribute('aria-hidden', 'true');
        
        // Return focus to trigger
        this.trigger?.focus();
        
        // Restore body scroll
        document.body.style.overflow = '';
    }
    
    handleKeydown(e) {
        if (e.key === 'Escape') {
            this.close();
            return;
        }
        
        if (e.key === 'Tab') {
            if (e.shiftKey) {
                if (document.activeElement === this.firstFocusable) {
                    e.preventDefault();
                    this.lastFocusable?.focus();
                }
            } else {
                if (document.activeElement === this.lastFocusable) {
                    e.preventDefault();
                    this.firstFocusable?.focus();
                }
            }
        }
    }
}

// Initialize all modals
document.addEventListener('DOMContentLoaded', () => {
    document.querySelectorAll('[data-modal-target]').forEach(modal => {
        new AccessibleModal(modal);
    });
});
```

## 5. Testing and Validation

### 5.1 Automated Accessibility Testing

```javascript
// Playwright accessibility test
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

test('artist page should be accessible', async ({ page }) => {
    await page.goto('/artists');
    
    const accessibilityScanResults = await new AxeBuilder({ page })
        .withTags(['wcag2a', 'wcag2aa', 'wcag21aa'])
        .analyze();
    
    expect(accessibilityScanResults.violations).toEqual([]);
});
```

## 6. Compliance Checklist

### 6.1 WCAG 2.1 AA Compliance Checklist

```markdown
## Perceivable
- [x] All images have appropriate alt text
- [x] Color contrast meets 4.5:1 ratio minimum
- [x] Text can be resized up to 200% without loss of functionality
- [x] Content is readable without color alone
- [x] Audio content has captions or transcripts

## Operable
- [x] All functionality is keyboard accessible
- [x] No content flashes more than 3 times per second
- [x] Users can pause, stop, or hide moving content
- [x] Page has descriptive titles
- [x] Focus order is logical and intuitive
- [x] Focus indicators are clearly visible

## Understandable
- [x] Page language is identified in HTML
- [x] Navigation is consistent across pages
- [x] Form labels and instructions are clear
- [x] Error messages are descriptive and helpful
- [x] Content appears and operates predictably

## Robust
- [x] Markup is valid and semantic
- [x] Content works with assistive technologies
- [x] ARIA attributes are used correctly
- [x] Interactive elements have accessible names
- [x] Status messages are announced to screen readers
```

---

## Navigation

- **Previous:** [Performance Standards](./performance/200-performance-standards.md)
- **Next:** [Visual Documentation Standards](./500-visual-documentation-standards.md)
- **Index:** [Chinook Documentation Index](./000-chinook-index.md)

## Related Documentation

- [Frontend Accessibility Guide](./frontend/140-accessibility-wcag-guide.md)
- [Accessibility Testing Guide](./testing/000-accessibility-testing-guide.md)

---

**Last Updated:** 2025-07-16  
**Maintainer:** Technical Documentation Team  
**Source:** [GitHub Repository](https://github.com/s-a-c/chinook)
