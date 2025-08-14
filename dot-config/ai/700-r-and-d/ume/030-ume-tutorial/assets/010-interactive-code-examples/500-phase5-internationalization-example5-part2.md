# Internationalization (Continued)

:::interactive-code
title: Implementing Comprehensive Internationalization (Part 2)
description: This example continues the demonstration of a robust internationalization system, focusing on translation management and content localization.
language: php
editable: true
code: |
  <?php
  
  namespace App\Models;
  
  use Illuminate\Database\Eloquent\Model;
  use Illuminate\Database\Eloquent\Relations\MorphTo;
  
  class Translation extends Model
  {
      protected $fillable = [
          'translatable_type',
          'translatable_id',
          'locale',
          'field',
          'value',
      ];
      
      /**
       * Get the translatable model.
       */
      public function translatable(): MorphTo
      {
          return $this->morphTo();
      }
      
      /**
       * Scope a query to only include translations for a specific locale.
       */
      public function scopeForLocale($query, string $locale)
      {
          return $query->where('locale', $locale);
      }
      
      /**
       * Scope a query to only include translations for a specific field.
       */
      public function scopeForField($query, string $field)
      {
          return $query->where('field', $field);
      }
  }
  
  namespace App\Traits;
  
  use App\Models\Translation;
  use Illuminate\Database\Eloquent\Relations\MorphMany;
  use Illuminate\Support\Facades\App;
  
  trait Translatable
  {
      /**
       * Get all translations for this model.
       */
      public function translations(): MorphMany
      {
          return $this->morphMany(Translation::class, 'translatable');
      }
      
      /**
       * Get the specified field in the specified locale.
       *
       * @param  string  $field
       * @param  string|null  $locale
       * @return mixed
       */
      public function translate(string $field, ?string $locale = null)
      {
          $locale = $locale ?: App::getLocale();
          $fallbackLocale = config('app.fallback_locale');
          
          // If the requested locale is the default locale, return the original value
          if ($locale === $fallbackLocale) {
              return $this->getAttribute($field);
          }
          
          // Get the translation for the requested locale
          $translation = $this->translations()
              ->forLocale($locale)
              ->forField($field)
              ->first();
          
          // If a translation exists, return it
          if ($translation) {
              return $translation->value;
          }
          
          // If no translation exists and the locale is not the fallback locale,
          // try to get the translation in the fallback locale
          if ($locale !== $fallbackLocale) {
              $fallbackTranslation = $this->translations()
                  ->forLocale($fallbackLocale)
                  ->forField($field)
                  ->first();
              
              if ($fallbackTranslation) {
                  return $fallbackTranslation->value;
              }
          }
          
          // If no translation exists in any locale, return the original value
          return $this->getAttribute($field);
      }
      
      /**
       * Set a translation for the specified field in the specified locale.
       *
       * @param  string  $field
       * @param  string  $value
       * @param  string|null  $locale
       * @return $this
       */
      public function setTranslation(string $field, string $value, ?string $locale = null)
      {
          $locale = $locale ?: App::getLocale();
          
          // If the locale is the default locale, update the original field
          if ($locale === config('app.fallback_locale')) {
              $this->setAttribute($field, $value);
              return $this;
          }
          
          // Find or create the translation
          $translation = $this->translations()
              ->forLocale($locale)
              ->forField($field)
              ->first();
          
          if ($translation) {
              $translation->update(['value' => $value]);
          } else {
              $this->translations()->create([
                  'locale' => $locale,
                  'field' => $field,
                  'value' => $value,
              ]);
          }
          
          return $this;
      }
      
      /**
       * Get all available translations for the specified field.
       *
       * @param  string  $field
       * @return array
       */
      public function getTranslations(string $field): array
      {
          $translations = $this->translations()
              ->forField($field)
              ->get()
              ->mapWithKeys(function ($translation) {
                  return [$translation->locale => $translation->value];
              })
              ->toArray();
          
          // Add the default value
          $translations[config('app.fallback_locale')] = $this->getAttribute($field);
          
          return $translations;
      }
      
      /**
       * Delete all translations for the specified field.
       *
       * @param  string  $field
       * @param  string|null  $locale
       * @return $this
       */
      public function deleteTranslations(string $field, ?string $locale = null)
      {
          $query = $this->translations()->forField($field);
          
          if ($locale) {
              $query->forLocale($locale);
          }
          
          $query->delete();
          
          return $this;
      }
      
      /**
       * Get the translatable fields for this model.
       *
       * @return array
       */
      public function getTranslatableFields(): array
      {
          return $this->translatableFields ?? [];
      }
      
      /**
       * Check if a field is translatable.
       *
       * @param  string  $field
       * @return bool
       */
      public function isTranslatable(string $field): bool
      {
          return in_array($field, $this->getTranslatableFields());
      }
      
      /**
       * Boot the trait.
       *
       * @return void
       */
      public static function bootTranslatable()
      {
          // Delete translations when the model is deleted
          static::deleting(function ($model) {
              if (method_exists($model, 'isForceDeleting') && !$model->isForceDeleting()) {
                  return;
              }
              
              $model->translations()->delete();
          });
      }
  }
  
  namespace App\Models;
  
  use App\Traits\Translatable;
  use Illuminate\Database\Eloquent\Model;
  
  class Product extends Model
  {
      use Translatable;
      
      protected $fillable = [
          'name',
          'description',
          'price',
          'category_id',
          'is_active',
      ];
      
      protected $translatableFields = [
          'name',
          'description',
      ];
      
      /**
       * Get the product's name in the current locale.
       *
       * @return string
       */
      public function getLocalizedNameAttribute(): string
      {
          return $this->translate('name');
      }
      
      /**
       * Get the product's description in the current locale.
       *
       * @return string
       */
      public function getLocalizedDescriptionAttribute(): string
      {
          return $this->translate('description');
      }
  }
:::
