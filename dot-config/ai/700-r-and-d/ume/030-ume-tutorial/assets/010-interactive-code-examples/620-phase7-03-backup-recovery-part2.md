# Backup and Recovery (Part 2)

:::interactive-code
title: Implementing Robust Backup and Recovery Systems (Part 2)
description: This example continues the demonstration of backup and recovery strategies, focusing on file backups and automated backup scheduling.
language: php
editable: true
code: |
  <?php
  
  namespace App\Console\Commands;
  
  use Illuminate\Console\Command;
  use Illuminate\Support\Facades\Storage;
  use Illuminate\Support\Facades\File;
  use Illuminate\Support\Facades\Log;
  use Illuminate\Support\Facades\DB;
  use ZipArchive;
  
  class BackupFiles extends Command
  {
      /**
       * The name and signature of the console command.
       *
       * @var string
       */
      protected $signature = 'backup:files
                              {--directories=uploads,public/images : Comma-separated list of directories to backup}
                              {--exclude=node_modules,vendor,storage/logs : Comma-separated list of directories to exclude}
                              {--storage=local : Storage disk to use (local, s3, etc.)}
                              {--path=backups/files : Path within the storage disk}';
      
      /**
       * The console command description.
       *
       * @var string
       */
      protected $description = 'Create a backup of specified files and directories';
      
      /**
       * Execute the console command.
       */
      public function handle()
      {
          $directories = $this->option('directories');
          $exclude = $this->option('exclude');
          $storageDisk = $this->option('storage');
          $storagePath = $this->option('path');
          
          $this->info("Starting file backup...");
          
          // Validate the storage disk
          if (!config("filesystems.disks.{$storageDisk}")) {
              $this->error("Storage disk '{$storageDisk}' does not exist.");
              return Command::FAILURE;
          }
          
          try {
              // Generate backup filename
              $timestamp = now()->format('Y-m-d_H-i-s');
              $filename = "backup_files_{$timestamp}.zip";
              
              // Create temporary directory if it doesn't exist
              $tempDir = storage_path('app/temp');
              if (!File::exists($tempDir)) {
                  File::makeDirectory($tempDir, 0755, true);
              }
              
              $tempFile = "{$tempDir}/{$filename}";
              
              // Get directories to backup
              $directoriesToBackup = explode(',', $directories);
              $directoriesToExclude = explode(',', $exclude);
              
              // Create the backup
              $fileCount = $this->createBackup($directoriesToBackup, $directoriesToExclude, $tempFile);
              
              if ($fileCount === 0) {
                  $this->error("No files found to backup.");
                  return Command::FAILURE;
              }
              
              // Store the backup
              $this->info("Storing backup to {$storageDisk} disk at {$storagePath}/{$filename}...");
              $backupPath = $this->storeBackup($tempFile, $storageDisk, $storagePath, $filename);
              
              // Clean up temporary files
              File::delete($tempFile);
              
              // Log the backup
              $this->logBackup($storageDisk, $backupPath, $fileCount);
              
              $this->info("File backup completed successfully: {$backupPath}");
              return Command::SUCCESS;
          } catch (\Exception $e) {
              $this->error("Backup failed: " . $e->getMessage());
              Log::error("File backup failed", [
                  'error' => $e->getMessage(),
                  'trace' => $e->getTraceAsString(),
              ]);
              return Command::FAILURE;
          }
      }
      
      /**
       * Create a file backup.
       *
       * @param array $directories
       * @param array $exclude
       * @param string $outputFile
       * @return int
       */
      protected function createBackup(array $directories, array $exclude, string $outputFile): int
      {
          $this->info("Creating backup file: {$outputFile}");
          
          $zip = new ZipArchive();
          
          if ($zip->open($outputFile, ZipArchive::CREATE | ZipArchive::OVERWRITE) !== true) {
              throw new \Exception("Cannot create zip file: {$outputFile}");
          }
          
          $fileCount = 0;
          $basePath = base_path();
          
          foreach ($directories as $directory) {
              $directory = trim($directory);
              $fullPath = $basePath . '/' . $directory;
              
              if (!File::exists($fullPath)) {
                  $this->warn("Directory does not exist: {$directory}");
                  continue;
              }
              
              $this->info("Backing up directory: {$directory}");
              
              // Get all files in the directory
              $files = File::allFiles($fullPath);
              
              foreach ($files as $file) {
                  $relativePath = $directory . '/' . $file->getRelativePathname();
                  
                  // Check if file should be excluded
                  $shouldExclude = false;
                  foreach ($exclude as $excludePattern) {
                      if (str_starts_with($relativePath, trim($excludePattern))) {
                          $shouldExclude = true;
                          break;
                      }
                  }
                  
                  if ($shouldExclude) {
                      continue;
                  }
                  
                  $zip->addFile($file->getRealPath(), $relativePath);
                  $fileCount++;
                  
                  // Show progress every 100 files
                  if ($fileCount % 100 === 0) {
                      $this->info("Processed {$fileCount} files...");
                  }
              }
          }
          
          // Add a manifest file
          $manifest = [
              'created_at' => now()->toDateTimeString(),
              'directories' => $directories,
              'exclude' => $exclude,
              'file_count' => $fileCount,
              'app_version' => config('app.version', '1.0.0'),
          ];
          
          $zip->addFromString('manifest.json', json_encode($manifest, JSON_PRETTY_PRINT));
          
          $zip->close();
          
          return $fileCount;
      }
      
      /**
       * Store the backup file to the specified storage disk.
       *
       * @param string $tempFile
       * @param string $storageDisk
       * @param string $storagePath
       * @param string $filename
       * @return string
       */
      protected function storeBackup(string $tempFile, string $storageDisk, string $storagePath, string $filename): string
      {
          $backupPath = "{$storagePath}/{$filename}";
          
          // Store the file
          Storage::disk($storageDisk)->put(
              $backupPath,
              file_get_contents($tempFile)
          );
          
          return $backupPath;
      }
      
      /**
       * Log the backup operation.
       *
       * @param string $storageDisk
       * @param string $backupPath
       * @param int $fileCount
       * @return void
       */
      protected function logBackup(string $storageDisk, string $backupPath, int $fileCount): void
      {
          Log::info("File backup created", [
              'storage_disk' => $storageDisk,
              'backup_path' => $backupPath,
              'file_count' => $fileCount,
              'size' => Storage::disk($storageDisk)->size($backupPath),
              'created_at' => now()->toDateTimeString(),
          ]);
          
          // Record backup in database
          DB::table('backup_history')->insert([
              'type' => 'files',
              'connection' => null,
              'storage_disk' => $storageDisk,
              'path' => $backupPath,
              'size' => Storage::disk($storageDisk)->size($backupPath),
              'file_count' => $fileCount,
              'created_at' => now(),
          ]);
      }
  }
:::
