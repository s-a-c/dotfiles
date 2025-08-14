# PHP 8 Attributes - Repeatable Attributes

:::interactive-code
title: Creating Repeatable Attributes
description: This example demonstrates how to create and use repeatable attributes that can be applied multiple times to the same element.
language: php
editable: true
code: |
  <?php
  
  // Define a repeatable attribute
  #[Attribute(Attribute::TARGET_CLASS | Attribute::IS_REPEATABLE)]
  class Tag {
      public function __construct(
          public string $name,
          public string $value = ''
      ) {}
  }
  
  // Apply multiple instances of the same attribute to a class
  #[Tag(name: 'category', value: 'tutorial')]
  #[Tag(name: 'language', value: 'php')]
  #[Tag(name: 'version', value: '8.0')]
  class Article {
      private string $title;
      private string $content;
      
      public function __construct(string $title, string $content) {
          $this->title = $title;
          $this->content = $content;
      }
      
      public function getTitle(): string {
          return $this->title;
      }
      
      public function getContent(): string {
          return $this->content;
      }
  }
  
  // Create an article
  $article = new Article(
      'Understanding PHP 8 Attributes',
      'PHP 8 introduces attributes, a powerful new feature...'
  );
  
  // Use reflection to read all Tag attributes
  $reflection = new ReflectionClass($article);
  $attributes = $reflection->getAttributes(Tag::class);
  
  echo "Article: {$article->getTitle()}\n";
  echo "Tags:\n";
  
  foreach ($attributes as $attribute) {
      $tag = $attribute->newInstance();
      echo "- {$tag->name}: {$tag->value}\n";
  }
  
  // Function to find articles by tag
  function findArticlesByTag(array $articles, string $tagName, string $tagValue): array {
      $results = [];
      
      foreach ($articles as $article) {
          $reflection = new ReflectionClass($article);
          $attributes = $reflection->getAttributes(Tag::class);
          
          foreach ($attributes as $attribute) {
              $tag = $attribute->newInstance();
              if ($tag->name === $tagName && $tag->value === $tagValue) {
                  $results[] = $article;
                  break; // Found a match, no need to check other tags
              }
          }
      }
      
      return $results;
  }
  
  // Example of how you might use the findArticlesByTag function
  // (not actually executed in this example)
  echo "\nExample of finding articles by tag:\n";
  echo "findArticlesByTag(\$articles, 'category', 'tutorial')";
explanation: |
  This example demonstrates how to create and use repeatable attributes:
  
  1. **Making Attributes Repeatable**: Add the `Attribute::IS_REPEATABLE` flag to the attribute definition to allow multiple instances of the same attribute on a single element.
  
  2. **Applying Multiple Attributes**: You can apply the same attribute multiple times to a class, method, property, etc., as long as it's marked as repeatable.
  
  3. **Reading Repeatable Attributes**: When using reflection, `getAttributes()` returns all instances of the attribute applied to the element.
  
  4. **Practical Use Case**: Repeatable attributes are useful for cases like tags, validation rules, routes, etc., where you might need multiple configurations on the same element.
  
  5. **Metadata for Filtering**: The example shows how you could use attributes as metadata for filtering objects (like finding articles with specific tags).
challenges:
  - Add a new Tag attribute with name 'difficulty' and value 'intermediate' to the Article class
  - Create a new repeatable attribute called 'Route' that can be applied to methods
  - Implement a function that counts how many tags of a specific name are applied to a class
  - Modify the Tag attribute to include a 'priority' parameter and sort the tags by priority
  - Create a second Article class with different tags and test the findArticlesByTag function
:::
