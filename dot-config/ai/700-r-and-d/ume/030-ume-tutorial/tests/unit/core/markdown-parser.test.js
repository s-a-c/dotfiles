/**
 * Unit tests for the Markdown parser
 */

// Import the functions to test
// In a real implementation, these would be imported from the actual module
// For now, we'll mock them for testing purposes
const {
  parseContent,
  parseBlock,
  generateHTML,
  processMarkdown
} = window.UMEInteractive ? window.UMEInteractive.MarkdownParser : {
  parseContent: () => [],
  parseBlock: () => null,
  generateHTML: () => '',
  processMarkdown: (content) => content
};

describe('Markdown Parser', () => {
  describe('parseContent', () => {
    it('should parse interactive code blocks', () => {
      const content = `
Some text before the block.

:::interactive-code
title: Example Title
description: Example description
language: php
code: |
  <?php
  echo "Hello, World!";
explanation: |
  This is an explanation.
:::

Some text after the block.
      `;

      const blocks = parseContent(content);

      expect(blocks).toHaveLength(1);
      expect(blocks[0]).toHaveProperty('title', 'Example Title');
      expect(blocks[0]).toHaveProperty('description', 'Example description');
      expect(blocks[0]).toHaveProperty('language', 'php');
      expect(blocks[0]).toHaveProperty('code', '<?php\necho "Hello, World!";');
      expect(blocks[0]).toHaveProperty('explanation', 'This is an explanation.');
    });

    it('should handle multiple blocks', () => {
      const content = `
:::interactive-code
title: First Example
description: First description
code: |
  <?php
  echo "First";
explanation: |
  First explanation.
:::

:::interactive-code
title: Second Example
description: Second description
code: |
  <?php
  echo "Second";
explanation: |
  Second explanation.
:::
      `;

      const blocks = parseContent(content);

      expect(blocks).toHaveLength(2);
      expect(blocks[0]).toHaveProperty('title', 'First Example');
      expect(blocks[1]).toHaveProperty('title', 'Second Example');
    });

    it('should handle unclosed blocks', () => {
      const content = `
:::interactive-code
title: Unclosed Block
description: This block is not closed properly
      `;

      const blocks = parseContent(content);

      expect(blocks).toHaveLength(0);
    });
  });

  describe('parseBlock', () => {
    it('should parse a block with all required parameters', () => {
      const blockContent = `
title: Example Title
description: Example description
code: |
  <?php
  echo "Hello, World!";
explanation: |
  This is an explanation.
      `;

      const block = parseBlock(blockContent);

      expect(block).toHaveProperty('title', 'Example Title');
      expect(block).toHaveProperty('description', 'Example description');
      expect(block).toHaveProperty('code', '<?php\necho "Hello, World!";');
      expect(block).toHaveProperty('explanation', 'This is an explanation.');
    });

    it('should return null if required parameters are missing', () => {
      const blockContent = `
title: Example Title
description: Example description
      `;

      const block = parseBlock(blockContent);

      expect(block).toBeNull();
    });

    it('should add default values for optional parameters', () => {
      const blockContent = `
title: Example Title
description: Example description
code: |
  <?php
  echo "Hello, World!";
explanation: |
  This is an explanation.
      `;

      const block = parseBlock(blockContent);

      expect(block).toHaveProperty('language', 'php');
      expect(block).toHaveProperty('editable', true);
    });
  });

  describe('generateHTML', () => {
    it('should generate HTML for a block', () => {
      const block = {
        title: 'Example Title',
        description: 'Example description',
        language: 'php',
        editable: true,
        code: '<?php\necho "Hello, World!";',
        explanation: 'This is an explanation.'
      };

      const html = generateHTML(block, 0);

      expect(html).toContain('Example Title');
      expect(html).toContain('Example description');
      expect(html).toContain('data-language="php"');
      expect(html).toContain('data-editable="true"');
      expect(html).toContain('data-code="&lt;?php\necho &quot;Hello, World!&quot;;"');
      expect(html).toContain('This is an explanation.');
    });

    it('should include challenges if provided', () => {
      const block = {
        title: 'Example Title',
        description: 'Example description',
        language: 'php',
        editable: true,
        code: '<?php\necho "Hello, World!";',
        explanation: 'This is an explanation.',
        challenges: 'These are challenges.'
      };

      const html = generateHTML(block, 0);

      expect(html).toContain('These are challenges.');
      expect(html).toContain('example-challenges');
    });

    it('should not include challenges if not provided', () => {
      const block = {
        title: 'Example Title',
        description: 'Example description',
        language: 'php',
        editable: true,
        code: '<?php\necho "Hello, World!";',
        explanation: 'This is an explanation.'
      };

      const html = generateHTML(block, 0);

      expect(html).not.toContain('example-challenges');
    });
  });

  describe('processMarkdown', () => {
    it('should replace interactive code blocks with HTML', () => {
      const content = `
Some text before the block.

:::interactive-code
title: Example Title
description: Example description
language: php
code: |
  <?php
  echo "Hello, World!";
explanation: |
  This is an explanation.
:::

Some text after the block.
      `;

      const processed = processMarkdown(content);

      expect(processed).toContain('Some text before the block.');
      expect(processed).toContain('Some text after the block.');
      expect(processed).toContain('interactive-code-example');
      expect(processed).not.toContain(':::interactive-code');
    });

    it('should handle multiple blocks', () => {
      const content = `
:::interactive-code
title: First Example
description: First description
code: |
  <?php
  echo "First";
explanation: |
  First explanation.
:::

:::interactive-code
title: Second Example
description: Second description
code: |
  <?php
  echo "Second";
explanation: |
  Second explanation.
:::
      `;

      const processed = processMarkdown(content);

      expect(processed).toContain('First Example');
      expect(processed).toContain('Second Example');
      expect(processed).toContain('interactive-code-example');
      expect(processed).not.toContain(':::interactive-code');
    });

    it('should handle content with no blocks', () => {
      const content = `
Some text with no interactive code blocks.

More text.
      `;

      const processed = processMarkdown(content);

      expect(processed).toBe(content);
    });
  });
});
