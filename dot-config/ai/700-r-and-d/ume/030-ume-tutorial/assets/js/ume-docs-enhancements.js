/**
 * UME Documentation Enhancements JavaScript
 *
 * This script provides enhanced functionality for the UME 010-consolidated-starter-kits including:
 * - Dark mode detection and support for diagrams
 * - Progress tracking
 * - Responsive navigation
 * - Mermaid diagram initialization
 */

document.addEventListener('DOMContentLoaded', function() {
  // Initialize all enhancements
  initMermaidDiagrams();
  setupDarkModeSupport();
  enhanceNavigation();
  setupProgressTracking();
});

/**
 * Initialize Mermaid diagrams with appropriate theme based on user's preference
 */
function initMermaidDiagrams() {
  if (typeof mermaid !== 'undefined') {
    const isDarkMode = document.documentElement.classList.contains('dark') ||
                       window.matchMedia('(prefers-color-scheme: dark)').matches;

    // Configure Mermaid with appropriate theme
    const config = {
      startOnLoad: true,
      theme: isDarkMode ? 'dark' : 'default',
      themeVariables: isDarkMode ? getDarkThemeVariables() : getLightThemeVariables()
    };

    mermaid.initialize(config);
  }
}

/**
 * Get theme variables for light mode
 */
function getLightThemeVariables() {
  return {
    primaryColor: '#f3f4f6',
    primaryBorderColor: '#6b7280',
    primaryTextColor: '#111827',
    secondaryColor: '#dbeafe',
    secondaryBorderColor: '#60a5fa',
    secondaryTextColor: '#1e40af',
    tertiaryColor: '#e5e7eb',
    tertiaryBorderColor: '#9ca3af',
    tertiaryTextColor: '#374151',
    noteTextColor: '#065f46',
    noteBkgColor: '#d1fae5',
    noteBorderColor: '#10b981',
    mainBkg: '#ffffff',
    lineColor: '#6b7280',
    textColor: '#111827'
  };
}

/**
 * Get theme variables for dark mode
 */
function getDarkThemeVariables() {
  return {
    primaryColor: '#374151',
    primaryBorderColor: '#6b7280',
    primaryTextColor: '#f3f4f6',
    secondaryColor: '#1e3a8a',
    secondaryBorderColor: '#60a5fa',
    secondaryTextColor: '#bfdbfe',
    tertiaryColor: '#4b5563',
    tertiaryBorderColor: '#9ca3af',
    tertiaryTextColor: '#d1d5db',
    noteTextColor: '#a7f3d0',
    noteBkgColor: '#064e3b',
    noteBorderColor: '#10b981',
    mainBkg: '#1f2937',
    lineColor: '#9ca3af',
    textColor: '#f3f4f6'
  };
}

/**
 * Setup dark mode support with event listeners for theme changes
 */
function setupDarkModeSupport() {
  // Listen for theme changes
  const darkModeMediaQuery = window.matchMedia('(prefers-color-scheme: dark)');
  darkModeMediaQuery.addEventListener('change', (e) => {
    initMermaidDiagrams();
  });

  // Check for manual theme toggles if they exist
  const themeToggle = document.getElementById('theme-toggle');
  if (themeToggle) {
    themeToggle.addEventListener('click', () => {
      // Allow time for the DOM to update with the new theme
      setTimeout(() => {
        initMermaidDiagrams();
      }, 100);
    });
  }
}

/**
 * Enhance navigation with responsive behavior and active state highlighting
 */
function enhanceNavigation() {
  // Add active state to current page in navigation
  const currentPath = window.location.pathname;
  const navLinks = document.querySelectorAll('nav a');

  navLinks.forEach(link => {
    const linkPath = link.getAttribute('href');
    if (linkPath && currentPath.includes(linkPath) && linkPath !== '/') {
      link.classList.add('active');

      // If in a nested navigation, expand parent sections
      const parentListItem = link.closest('li').parentElement.closest('li');
      if (parentListItem) {
        const parentExpander = parentListItem.querySelector('.expander');
        if (parentExpander) {
          parentExpander.classList.add('expanded');
          const parentList = parentListItem.querySelector('ul');
          if (parentList) {
            parentList.style.display = 'block';
          }
        }
      }
    }
  });

  // Setup mobile navigation toggle if it exists
  const mobileNavToggle = document.getElementById('mobile-nav-toggle');
  const siteNavigation = document.getElementById('site-navigation');

  if (mobileNavToggle && siteNavigation) {
    mobileNavToggle.addEventListener('click', () => {
      siteNavigation.classList.toggle('mobile-visible');
      mobileNavToggle.setAttribute(
        'aria-expanded',
        mobileNavToggle.getAttribute('aria-expanded') === 'true' ? 'false' : 'true'
      );
    });
  }
}

/**
 * Setup progress tracking for tutorial sections
 */
function setupProgressTracking() {
  // Check if we should track progress (only in tutorial sections)
  const isTutorialSection = document.body.classList.contains('tutorial-section');
  if (!isTutorialSection) return;

  // Get or initialize progress data from localStorage
  let progressData = JSON.parse(localStorage.getItem('ume-tutorial-progress') || '{}');
  const currentPath = window.location.pathname;

  // Mark current page as visited
  progressData[currentPath] = {
    visited: true,
    timestamp: new Date().toISOString()
  };

  // Save updated progress
  localStorage.setItem('ume-tutorial-progress', JSON.stringify(progressData));

  // Update progress indicators in the UI
  updateProgressIndicators(progressData);
}

/**
 * Update progress indicators in the UI based on stored progress data
 */
function updateProgressIndicators(progressData) {
  // Update navigation items with progress indicators
  const navLinks = document.querySelectorAll('nav a');

  navLinks.forEach(link => {
    const linkPath = link.getAttribute('href');
    if (linkPath && progressData[linkPath] && progressData[linkPath].visited) {
      // Add a checkmark or other indicator
      if (!link.querySelector('.progress-indicator')) {
        const indicator = document.createElement('span');
        indicator.classList.add('progress-indicator');
        indicator.innerHTML = '✓';
        link.appendChild(indicator);
      }
    }
  });

  // Update overall progress if a progress bar exists
  const progressBar = document.getElementById('tutorial-progress-bar');
  if (progressBar) {
    const totalSections = document.querySelectorAll('.tutorial-section-link').length;
    const completedSections = Object.keys(progressData).length;
    const progressPercentage = Math.round((completedSections / totalSections) * 100);

    progressBar.style.width = `${progressPercentage}%`;
    progressBar.setAttribute('aria-valuenow', progressPercentage);

    const progressText = document.getElementById('tutorial-progress-text');
    if (progressText) {
      progressText.textContent = `${progressPercentage}% Complete`;
    }
  }
}
