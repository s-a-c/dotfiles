# Accessibility Testing Guide

**Version:** 1.0  
**Created:** 2025-07-16  
**Last Updated:** 2025-07-16  
**Scope:** WCAG 2.1 AA compliance testing for Chinook project

## Table of Contents

1. [Overview](#1-overview)
2. [Testing Tools Setup](#2-testing-tools-setup)
3. [Automated Testing](#3-automated-testing)
4. [Manual Testing](#4-manual-testing)
5. [CI/CD Integration](#5-cicd-integration)
6. [Compliance Checklist](#6-compliance-checklist)

## 1. Overview

This guide establishes comprehensive accessibility testing procedures for the Chinook project, ensuring WCAG 2.1 AA compliance across all user interfaces.

### 1.1 Testing Scope

- **Filament Admin Panel:** All resource pages, forms, and navigation
- **Frontend Views:** Public-facing pages and components
- **Documentation:** All markdown files and generated HTML
- **API Responses:** JSON structure and error messages

### 1.2 Compliance Standards

- **WCAG 2.1 AA:** Primary compliance target
- **Section 508:** US federal accessibility requirements
- **EN 301 549:** European accessibility standard

## 2. Testing Tools Setup

### 2.1 Browser Extensions

```bash
# Install accessibility testing extensions
# Chrome/Edge: axe DevTools, WAVE, Lighthouse
# Firefox: axe DevTools, WAVE

# Recommended extensions:
# - axe DevTools (Deque Systems)
# - WAVE Web Accessibility Evaluator
# - Lighthouse (built into Chrome DevTools)
# - Colour Contrast Analyser
```

### 2.2 Node.js Testing Tools

```bash
# Install accessibility testing packages
npm install --save-dev @axe-core/playwright axe-core pa11y lighthouse-ci

# Install Playwright for automated testing
npm install --save-dev @playwright/test

# Install additional accessibility tools
npm install --save-dev accessibility-checker jest-axe
```

### 2.3 PHP Testing Tools

```bash
# Install accessibility testing for Laravel
composer require --dev dms/phpunit-arraysubset-asserts
composer require --dev spatie/laravel-html

# For Filament-specific testing
composer require --dev filament/testing
```

## 3. Automated Testing

### 3.1 Playwright Accessibility Tests

```javascript
// tests/accessibility/basic-accessibility.spec.js
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

test.describe('Chinook Accessibility Tests', () => {
    test('homepage should be accessible', async ({ page }) => {
        await page.goto('/');
        
        const accessibilityScanResults = await new AxeBuilder({ page })
            .withTags(['wcag2a', 'wcag2aa', 'wcag21aa'])
            .analyze();
        
        expect(accessibilityScanResults.violations).toEqual([]);
    });

    test('artist listing should be accessible', async ({ page }) => {
        await page.goto('/artists');
        
        const accessibilityScanResults = await new AxeBuilder({ page })
            .withTags(['wcag2a', 'wcag2aa', 'wcag21aa'])
            .exclude('#non-critical-banner') // Exclude known issues
            .analyze();
        
        expect(accessibilityScanResults.violations).toEqual([]);
    });

    test('filament admin panel should be accessible', async ({ page }) => {
        // Login to admin panel
        await page.goto('/chinook-fm/login');
        await page.fill('[name="email"]', 'admin@chinook.test');
        await page.fill('[name="password"]', 'password');
        await page.click('button[type="submit"]');
        
        // Test dashboard accessibility
        await page.goto('/chinook-fm');
        
        const accessibilityScanResults = await new AxeBuilder({ page })
            .withTags(['wcag2a', 'wcag2aa', 'wcag21aa'])
            .analyze();
        
        expect(accessibilityScanResults.violations).toEqual([]);
    });
});
```

### 3.2 Laravel Feature Tests with Accessibility

```php
<?php

namespace Tests\Feature\Accessibility;

use App\Models\Chinook\Artist;use App\Models\User;use Illuminate\Foundation\Testing\RefreshDatabase;use old\TestCase;

/**
 * Accessibility Feature Tests
 * 
 * Tests accessibility compliance for Laravel views and components.
 * Focuses on server-side rendered content and semantic HTML.
 */
class AccessibilityTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Test homepage accessibility structure
     */
    public function test_homepage_has_proper_semantic_structure(): void
    {
        $response = $this->get('/');
        
        $response->assertStatus(200);
        
        // Check for proper heading hierarchy
        $response->assertSee('<h1', false);
        $response->assertDontSee('<h3', false); // Should not skip h2
        
        // Check for main landmark
        $response->assertSee('<main', false);
        
        // Check for navigation landmark
        $response->assertSee('<nav', false);
        
        // Check for skip links
        $response->assertSee('Skip to main content');
    }

    /**
     * Test form accessibility
     */
    public function test_forms_have_proper_labels_and_structure(): void
    {
        $user = User::factory()->create();
        
        $response = $this->actingAs($user)->get('/chinook-fm/artists/create');
        
        $response->assertStatus(200);
        
        // Check for proper form labels
        $response->assertSee('<label', false);
        
        // Check for required field indicators
        $response->assertSee('required', false);
        
        // Check for error message containers
        $response->assertSee('aria-describedby', false);
    }

    /**
     * Test table accessibility
     */
    public function test_data_tables_have_proper_headers(): void
    {
        Artist::factory()->count(5)->create();
        
        $response = $this->get('/artists');
        
        $response->assertStatus(200);
        
        // Check for table headers
        $response->assertSee('<th', false);
        
        // Check for table caption or summary
        $response->assertSeeAny(['<caption', 'aria-label'], false);
        
        // Check for proper table structure
        $response->assertSee('<thead', false);
        $response->assertSee('<tbody', false);
    }
}
```

### 3.3 Pa11y Configuration

```javascript
// .pa11yrc.js
module.exports = {
    standard: 'WCAG2AA',
    level: 'error',
    reporter: 'json',
    ignore: [
        // Ignore specific issues that are false positives
        'WCAG2AA.Principle1.Guideline1_4.1_4_3.G18.Fail'
    ],
    urls: [
        'http://localhost:8000/',
        'http://localhost:8000/artists',
        'http://localhost:8000/albums',
        'http://localhost:8000/chinook-fm/login'
    ],
    actions: [
        // Login action for protected pages
        'set field [name="email"] to admin@chinook.test',
        'set field [name="password"] to password',
        'click element button[type="submit"]',
        'wait for url to be http://localhost:8000/chinook-fm'
    ]
};
```

## 4. Manual Testing

### 4.1 Keyboard Navigation Testing

```javascript
// Manual testing checklist for keyboard navigation
const keyboardTestingChecklist = {
    navigation: [
        'Tab through all interactive elements',
        'Verify focus indicators are visible',
        'Test skip links functionality',
        'Verify logical tab order'
    ],
    forms: [
        'Navigate forms using Tab and Shift+Tab',
        'Test form submission with Enter key',
        'Verify error messages are announced',
        'Test dropdown and select navigation'
    ],
    modals: [
        'Test modal opening with keyboard',
        'Verify focus trapping in modals',
        'Test modal closing with Escape key',
        'Verify focus return after modal close'
    ]
};
```

### 4.2 Screen Reader Testing

```bash
# Screen reader testing commands (macOS VoiceOver)
# Enable VoiceOver: Cmd + F5
# Navigate by headings: VO + Cmd + H
# Navigate by links: VO + Cmd + L
# Navigate by form controls: VO + Cmd + J

# Test scenarios:
# 1. Navigate entire page structure
# 2. Fill out and submit forms
# 3. Interact with data tables
# 4. Use search functionality
```

## 5. CI/CD Integration

### 5.1 GitHub Actions Workflow

```yaml
# .github/workflows/accessibility.yml
name: Accessibility Testing

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  accessibility:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: '20'
        cache: 'npm'
    
    - name: Install dependencies
      run: npm ci
    
    - name: Setup Laravel
      run: |
        composer install
        cp .env.example .env
        php artisan key:generate
        php artisan migrate --seed
    
    - name: Start Laravel server
      run: php artisan serve &
      
    - name: Wait for server
      run: sleep 10
    
    - name: Run Pa11y tests
      run: npx pa11y-ci
    
    - name: Run Playwright accessibility tests
      run: npx playwright test tests/accessibility/
    
    - name: Upload test results
      uses: actions/upload-artifact@v4
      if: failure()
      with:
        name: accessibility-test-results
        path: test-results/
```

## 6. Compliance Checklist

### 6.1 WCAG 2.1 AA Checklist

```markdown
## Perceivable
- [ ] All images have appropriate alt text
- [ ] Color is not the only means of conveying information
- [ ] Text has sufficient contrast ratio (4.5:1 minimum)
- [ ] Content is readable when zoomed to 200%
- [ ] Audio content has captions or transcripts

## Operable
- [ ] All functionality is keyboard accessible
- [ ] No content flashes more than 3 times per second
- [ ] Users can pause, stop, or hide moving content
- [ ] Page has descriptive titles
- [ ] Focus order is logical and intuitive

## Understandable
- [ ] Page language is identified
- [ ] Navigation is consistent across pages
- [ ] Form labels and instructions are clear
- [ ] Error messages are descriptive and helpful
- [ ] Content appears and operates predictably

## Robust
- [ ] Markup is valid and semantic
- [ ] Content works with assistive technologies
- [ ] ARIA attributes are used correctly
- [ ] Interactive elements have accessible names
```

---

## Navigation

- **Previous:** [Testing Index](./000-testing-index.md)
- **Next:** [Performance Testing Guide](./100-performance-testing-guide.md)
- **Index:** [Chinook Documentation Index](../000-chinook-index.md)

## Related Documentation

- [Frontend Accessibility Guide](../frontend/140-accessibility-wcag-guide.md)
- [Documentation Style Guide](../000-documentation-style-guide.md)

---

**Last Updated:** 2025-07-16  
**Maintainer:** Technical Documentation Team  
**Source:** [GitHub Repository](https://github.com/s-a-c/chinook)
