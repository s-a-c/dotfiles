/**
 * Build script for UME Tutorial Interactive Code Examples
 * 
 * This script:
 * 1. Converts Markdown files to HTML
 * 2. Applies syntax highlighting to code blocks
 * 3. Generates index pages for each phase
 * 4. Creates a sitemap
 */

const fs = require('fs');
const path = require('path');
const marked = require('marked');
const hljs = require('highlight.js');

// Configure marked with syntax highlighting
marked.setOptions({
  highlight: function(code, lang) {
    if (lang && hljs.getLanguage(lang)) {
      return hljs.highlight(code, { language: lang }).value;
    }
    return hljs.highlightAuto(code).value;
  }
});

// Directory paths
const sourceDir = './';
const outputDir = './dist';

// Create output directory if it doesn't exist
if (!fs.existsSync(outputDir)) {
  fs.mkdirSync(outputDir, { recursive: true });
}

// Copy static assets
function copyStaticAssets() {
  console.log('Copying static assets...');
  
  // CSS files
  fs.copyFileSync(
    path.join(sourceDir, 'styles.css'),
    path.join(outputDir, 'styles.css')
  );
  
  // JavaScript files
  fs.copyFileSync(
    path.join(sourceDir, 'scripts-part1.js'),
    path.join(outputDir, 'scripts-part1.js')
  );
  fs.copyFileSync(
    path.join(sourceDir, 'scripts-part2.js'),
    path.join(outputDir, 'scripts-part2.js')
  );
  fs.copyFileSync(
    path.join(sourceDir, 'scripts-part3.js'),
    path.join(outputDir, 'scripts-part3.js')
  );
  
  // Other static files
  fs.copyFileSync(
    path.join(sourceDir, 'robots.txt'),
    path.join(outputDir, 'robots.txt')
  );
  fs.copyFileSync(
    path.join(sourceDir, 'sitemap.xml'),
    path.join(outputDir, 'sitemap.xml')
  );
  
  console.log('Static assets copied successfully.');
}

// Convert Markdown files to HTML
function convertMarkdownFiles() {
  console.log('Converting Markdown files to HTML...');
  
  const mdFiles = fs.readdirSync(sourceDir).filter(file => file.endsWith('.md'));
  
  mdFiles.forEach(file => {
    const filePath = path.join(sourceDir, file);
    const content = fs.readFileSync(filePath, 'utf8');
    const htmlContent = marked.parse(content);
    
    // Extract title from markdown
    const titleMatch = content.match(/^# (.+)$/m);
    const title = titleMatch ? titleMatch[1] : 'UME Tutorial';
    
    // Create HTML file
    const htmlFile = file.replace('.md', '.html');
    const htmlPath = path.join(outputDir, htmlFile);
    
    // Create HTML template
    const html = `
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>${title} - UME Tutorial</title>
        <link rel="stylesheet" href="styles.css">
        <script src="scripts-part1.js"></script>
        <script src="scripts-part2.js"></script>
        <script src="scripts-part3.js"></script>
      </head>
      <body>
        <header>
          <h1>UME Tutorial Interactive Code Examples</h1>
          <div class="controls">
            <button id="theme-toggle">Switch to Dark Theme</button>
            <button id="contrast-toggle">Enable High Contrast</button>
          </div>
        </header>
        
        <nav>
          <h2>Navigation</h2>
          <ul>
            <li><a href="index.html">Home</a></li>
            <li>
              <span>Phases</span>
              <ul>
                <li><a href="phase0-index.html">Phase 0: Foundation</a></li>
                <li><a href="phase1-index.html">Phase 1: Core Models & STI</a></li>
                <li><a href="phase2-index.html">Phase 2: Auth & Profiles</a></li>
                <li><a href="phase3-index.html">Phase 3: Advanced User Management</a></li>
                <li><a href="phase4-index.html">Phase 4: Real-time Features</a></li>
                <li><a href="phase5-index.html">Phase 5: Advanced Features</a></li>
                <li><a href="phase6-index.html">Phase 6: Testing and Quality Assurance</a></li>
                <li><a href="phase7-index.html">Phase 7: Deployment and Maintenance</a></li>
              </ul>
            </li>
            <li>
              <span>Resources</span>
              <ul>
                <li><a href="all-phases-summary.html">All Phases Summary</a></li>
                <li><a href="using-interactive-examples.html">Using Interactive Examples</a></li>
                <li><a href="browser-compatibility-report.html">Browser Compatibility</a></li>
                <li><a href="device-compatibility-report.html">Device Compatibility</a></li>
              </ul>
            </li>
          </ul>
        </nav>
        
        <main>
          ${htmlContent}
        </main>
        
        <footer>
          <p>&copy; 2023 StandAloneComplex. Licensed under the <a href="LICENSE.html">MIT License</a>.</p>
          <p>
            <a href="CHANGELOG.html">Changelog</a> |
            <a href="CONTRIBUTORS.html">Contributors</a> |
            <a href="future-enhancements.html">Future Enhancements</a>
          </p>
        </footer>
      </body>
      </html>
    `;
    
    fs.writeFileSync(htmlPath, html);
    console.log(`Converted ${file} to ${htmlFile}`);
  });
  
  console.log('Markdown files converted successfully.');
}

// Generate index pages for each phase
function generatePhaseIndexes() {
  console.log('Generating phase index pages...');
  
  // Read manifest file
  const manifest = JSON.parse(fs.readFileSync(path.join(sourceDir, 'manifest.json'), 'utf8'));
  
  // Generate index for each phase
  manifest.phases.forEach(phase => {
    const phaseId = phase.id;
    const phaseName = phase.name;
    const phaseDescription = phase.description;
    
    // Find examples for this phase
    const examples = manifest.examples.filter(example => example.phase === phaseId);
    
    // Create HTML content
    let htmlContent = `
      <h1>Phase ${phaseId}: ${phaseName}</h1>
      <p>${phaseDescription}</p>
      
      <h2>Examples in this Phase</h2>
      <ul>
    `;
    
    // Add examples
    examples.forEach(example => {
      htmlContent += `
        <li>
          <a href="${example.file.replace('.md', '.html')}">
            ${example.title}
          </a>
        </li>
      `;
    });
    
    htmlContent += `
      </ul>
      
      <h2>Next Steps</h2>
      <p>
        After completing these examples, continue to 
        <a href="phase${phaseId + 1}-index.html">Phase ${phaseId + 1}</a>
        or return to the <a href="index.html">main index</a>.
      </p>
    `;
    
    // Create HTML file
    const htmlFile = `phase${phaseId}-index.html`;
    const htmlPath = path.join(outputDir, htmlFile);
    
    // Create HTML template
    const html = `
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Phase ${phaseId}: ${phaseName} - UME Tutorial</title>
        <link rel="stylesheet" href="styles.css">
        <script src="scripts-part1.js"></script>
        <script src="scripts-part2.js"></script>
        <script src="scripts-part3.js"></script>
      </head>
      <body>
        <header>
          <h1>UME Tutorial Interactive Code Examples</h1>
          <div class="controls">
            <button id="theme-toggle">Switch to Dark Theme</button>
            <button id="contrast-toggle">Enable High Contrast</button>
          </div>
        </header>
        
        <nav>
          <h2>Navigation</h2>
          <ul>
            <li><a href="index.html">Home</a></li>
            <li>
              <span>Phases</span>
              <ul>
                <li><a href="phase0-index.html">Phase 0: Foundation</a></li>
                <li><a href="phase1-index.html">Phase 1: Core Models & STI</a></li>
                <li><a href="phase2-index.html">Phase 2: Auth & Profiles</a></li>
                <li><a href="phase3-index.html">Phase 3: Advanced User Management</a></li>
                <li><a href="phase4-index.html">Phase 4: Real-time Features</a></li>
                <li><a href="phase5-index.html">Phase 5: Advanced Features</a></li>
                <li><a href="phase6-index.html">Phase 6: Testing and Quality Assurance</a></li>
                <li><a href="phase7-index.html">Phase 7: Deployment and Maintenance</a></li>
              </ul>
            </li>
            <li>
              <span>Resources</span>
              <ul>
                <li><a href="all-phases-summary.html">All Phases Summary</a></li>
                <li><a href="using-interactive-examples.html">Using Interactive Examples</a></li>
                <li><a href="browser-compatibility-report.html">Browser Compatibility</a></li>
                <li><a href="device-compatibility-report.html">Device Compatibility</a></li>
              </ul>
            </li>
          </ul>
        </nav>
        
        <main>
          ${htmlContent}
        </main>
        
        <footer>
          <p>&copy; 2023 StandAloneComplex. Licensed under the <a href="LICENSE.html">MIT License</a>.</p>
          <p>
            <a href="CHANGELOG.html">Changelog</a> |
            <a href="CONTRIBUTORS.html">Contributors</a> |
            <a href="future-enhancements.html">Future Enhancements</a>
          </p>
        </footer>
      </body>
      </html>
    `;
    
    fs.writeFileSync(htmlPath, html);
    console.log(`Generated ${htmlFile}`);
  });
  
  console.log('Phase index pages generated successfully.');
}

// Main build function
function build() {
  console.log('Starting build process...');
  
  // Create output directory
  if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
  }
  
  // Copy static assets
  copyStaticAssets();
  
  // Convert Markdown files to HTML
  convertMarkdownFiles();
  
  // Generate phase index pages
  generatePhaseIndexes();
  
  console.log('Build completed successfully!');
}

// Run the build
build();
