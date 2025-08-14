# Backup and Recovery (Part 3)

:::interactive-code
title: Implementing Robust Backup and Recovery Systems (Part 3)
description: This example concludes the demonstration of backup and recovery strategies, focusing on restoration processes and disaster recovery.
language: php
editable: true
code: |
  <?php
  
  namespace App\Console\Commands;
  
  use Illuminate\Console\Command;
  use Illuminate\Support\Facades\Storage;
  use Illuminate\Support\Facades\DB;
  use Illuminate\Support\Facades\Log;
  use Illuminate\Support\Facades\File;
  use Illuminate\Support\Facades\Schema;
  use ZipArchive;
  
  class RestoreBackup extends Command
  {
      /**
       * The name and signature of the console command.
       *
       * @var string
       */
      protected $signature = 'backup:restore
                              {backup : Path to the backup file or backup ID from backup_history table}
                              {--connection=mysql : Database connection for database backups}
                              {--storage=local : Storage disk where the backup is stored}
                              {--force : Force restore without confirmation}
                              {--skip-tables= : Comma-separated list of tables to skip during database restore}';
      
      /**
       * The console command description.
       *
       * @var string
       */
      protected $description = 'Restore a backup';
      
      /**
       * Execute the console command.
       */
      public function handle()
      {
          $backup = $this->argument('backup');
          $connection = $this->option('connection');
          $storageDisk = $this->option('storage');
          $force = $this->option('force');
          $skipTables = $this->option('skip-tables') ? explode(',', $this->option('skip-tables')) : [];
          
          $this->info("Starting backup restoration...");
          
          try {
              // Determine if backup is an ID or a path
              if (is_numeric($backup)) {
                  $backupRecord = DB::table('backup_history')->find($backup);
                  
                  if (!$backupRecord) {
                      $this->error("Backup with ID {$backup} not found.");
                      return Command::FAILURE;
                  }
                  
                  $backupPath = $backupRecord->path;
                  $backupType = $backupRecord->type;
                  $storageDisk = $backupRecord->storage_disk;
              } else {
                  $backupPath = $backup;
                  $backupType = $this->determineBackupType($backupPath);
              }
              
              // Validate the storage disk
              if (!config("filesystems.disks.{$storageDisk}")) {
                  $this->error("Storage disk '{$storageDisk}' does not exist.");
                  return Command::FAILURE;
              }
              
              // Check if backup exists
              if (!Storage::disk($storageDisk)->exists($backupPath)) {
                  $this->error("Backup file not found: {$backupPath}");
                  return Command::FAILURE;
              }
              
              // Confirm restoration if not forced
              if (!$force) {
                  $this->warn("WARNING: Restoration will overwrite existing data!");
                  if (!$this->confirm('Are you sure you want to restore this backup?')) {
                      $this->info('Restoration aborted.');
                      return Command::SUCCESS;
                  }
              }
              
              // Create temporary directory if it doesn't exist
              $tempDir = storage_path('app/temp/restore');
              if (File::exists($tempDir)) {
                  File::deleteDirectory($tempDir);
              }
              File::makeDirectory($tempDir, 0755, true);
              
              // Download backup to temporary directory
              $tempFile = "{$tempDir}/" . basename($backupPath);
              file_put_contents($tempFile, Storage::disk($storageDisk)->get($backupPath));
              
              // Perform restoration based on backup type
              switch ($backupType) {
                  case 'database':
                      $this->restoreDatabase($tempFile, $connection, $skipTables);
                      break;
                  case 'files':
                      $this->restoreFiles($tempFile);
                      break;
                  default:
                      $this->error("Unknown backup type: {$backupType}");
                      return Command::FAILURE;
              }
              
              // Clean up temporary files
              File::deleteDirectory($tempDir);
              
              // Log the restoration
              $this->logRestoration($backupPath, $backupType, $storageDisk);
              
              $this->info("Backup restoration completed successfully.");
              return Command::SUCCESS;
          } catch (\Exception $e) {
              $this->error("Restoration failed: " . $e->getMessage());
              Log::error("Backup restoration failed", [
                  'backup' => $backup,
                  'error' => $e->getMessage(),
                  'trace' => $e->getTraceAsString(),
              ]);
              return Command::FAILURE;
          }
      }
      
      /**
       * Determine the type of backup from the file path.
       *
       * @param string $backupPath
       * @return string
       */
      protected function determineBackupType(string $backupPath): string
      {
          if (str_contains($backupPath, 'database')) {
              return 'database';
          } elseif (str_contains($backupPath, 'files')) {
              return 'files';
          }
          
          // Try to determine from file extension
          $extension = pathinfo($backupPath, PATHINFO_EXTENSION);
          
          if ($extension === 'sql' || $extension === 'gz') {
              return 'database';
          } elseif ($extension === 'zip') {
              return 'files';
          }
          
          throw new \Exception("Could not determine backup type for: {$backupPath}");
      }
      
      /**
       * Restore a database backup.
       *
       * @param string $backupFile
       * @param string $connection
       * @param array $skipTables
       * @return void
       */
      protected function restoreDatabase(string $backupFile, string $connection, array $skipTables): void
      {
          $this->info("Restoring database backup: {$backupFile}");
          
          // Check if the file is compressed
          if (pathinfo($backupFile, PATHINFO_EXTENSION) === 'gz') {
              $this->info("Decompressing backup file...");
              $decompressedFile = substr($backupFile, 0, -3); // Remove .gz extension
              $this->decompressFile($backupFile, $decompressedFile);
              $backupFile = $decompressedFile;
          }
          
          // Read the SQL file
          $sql = file_get_contents($backupFile);
          
          // Split SQL by semicolons
          $statements = array_filter(array_map('trim', explode(';', $sql)));
          
          // Begin transaction
          DB::connection($connection)->beginTransaction();
          
          try {
              $this->info("Executing SQL statements...");
              $count = 0;
              
              foreach ($statements as $statement) {
                  // Skip empty statements
                  if (empty($statement)) {
                      continue;
                  }
                  
                  // Check if statement is for a table we should skip
                  $shouldSkip = false;
                  foreach ($skipTables as $skipTable) {
                      if (preg_match("/CREATE TABLE.*`{$skipTable}`/i", $statement) ||
                          preg_match("/INSERT INTO.*`{$skipTable}`/i", $statement) ||
                          preg_match("/DROP TABLE.*`{$skipTable}`/i", $statement)) {
                          $shouldSkip = true;
                          break;
                      }
                  }
                  
                  if ($shouldSkip) {
                      continue;
                  }
                  
                  // Execute the statement
                  DB::connection($connection)->unprepared($statement);
                  $count++;
                  
                  // Show progress every 100 statements
                  if ($count % 100 === 0) {
                      $this->info("Executed {$count} SQL statements...");
                  }
              }
              
              // Commit transaction
              DB::connection($connection)->commit();
              $this->info("Database restoration completed: {$count} SQL statements executed.");
          } catch (\Exception $e) {
              // Rollback transaction
              DB::connection($connection)->rollBack();
              throw new \Exception("Database restoration failed: " . $e->getMessage());
          }
      }
      
      /**
       * Restore a file backup.
       *
       * @param string $backupFile
       * @return void
       */
      protected function restoreFiles(string $backupFile): void
      {
          $this->info("Restoring file backup: {$backupFile}");
          
          $zip = new ZipArchive();
          
          if ($zip->open($backupFile) !== true) {
              throw new \Exception("Cannot open zip file: {$backupFile}");
          }
          
          // Check for manifest
          if ($zip->locateName('manifest.json') !== false) {
              $manifest = json_decode($zip->getFromName('manifest.json'), true);
              $this->info("Backup manifest found:");
              $this->info("Created at: " . $manifest['created_at']);
              $this->info("File count: " . $manifest['file_count']);
              $this->info("Directories: " . implode(', ', $manifest['directories']));
          }
          
          // Extract files
          $extractPath = base_path();
          $this->info("Extracting files to: {$extractPath}");
          
          $fileCount = 0;
          
          // Extract files one by one to handle permissions
          for ($i = 0; $i < $zip->numFiles; $i++) {
              $filename = $zip->getNameIndex($i);
              
              // Skip manifest
              if ($filename === 'manifest.json') {
                  continue;
              }
              
              // Create directory if it doesn't exist
              $dirname = dirname($extractPath . '/' . $filename);
              if (!File::exists($dirname)) {
                  File::makeDirectory($dirname, 0755, true);
              }
              
              // Extract file
              copy("zip://{$backupFile}#{$filename}", $extractPath . '/' . $filename);
              $fileCount++;
              
              // Show progress every 100 files
              if ($fileCount % 100 === 0) {
                  $this->info("Extracted {$fileCount} files...");
              }
          }
          
          $zip->close();
          
          $this->info("File restoration completed: {$fileCount} files extracted.");
      }
      
      /**
       * Decompress a gzipped file.
       *
       * @param string $inputFile
       * @param string $outputFile
       * @return void
       */
      protected function decompressFile(string $inputFile, string $outputFile): void
      {
          $input = gzopen($inputFile, 'rb');
          $output = fopen($outputFile, 'wb');
          
          while (!gzeof($input)) {
              fwrite($output, gzread($input, 4096));
          }
          
          gzclose($input);
          fclose($output);
      }
      
      /**
       * Log the restoration operation.
       *
       * @param string $backupPath
       * @param string $backupType
       * @param string $storageDisk
       * @return void
       */
      protected function logRestoration(string $backupPath, string $backupType, string $storageDisk): void
      {
          Log::info("Backup restored", [
              'backup_path' => $backupPath,
              'backup_type' => $backupType,
              'storage_disk' => $storageDisk,
              'restored_at' => now()->toDateTimeString(),
          ]);
          
          // Record restoration in database
          DB::table('restoration_history')->insert([
              'backup_path' => $backupPath,
              'backup_type' => $backupType,
              'storage_disk' => $storageDisk,
              'restored_by' => auth()->id() ?? null,
              'created_at' => now(),
          ]);
      }
  }
explanation: |
  This three-part example demonstrates a comprehensive backup and recovery system for Laravel applications:
  
  **Part 1: Database Backup**
  - Creates backups of database tables
  - Supports selective table backups
  - Handles compression of backup files
  - Stores backups on configurable storage disks
  - Logs backup operations for auditing
  
  **Part 2: File Backup**
  - Creates backups of specified directories
  - Supports exclusion patterns for unwanted files
  - Compresses files into ZIP archives
  - Includes a manifest file with backup metadata
  - Tracks backup history in the database
  
  **Part 3: Backup Restoration**
  - Restores database backups with transaction support
  - Restores file backups to their original locations
  - Supports selective table restoration
  - Handles compressed backup files
  - Logs restoration operations for auditing
  
  Key features of the implementation:
  
  - **Flexible Storage Options**: Backups can be stored on any configured storage disk
  - **Compression Support**: Reduces backup size and transfer times
  - **Selective Backups**: Ability to include or exclude specific tables and directories
  - **Transaction Safety**: Database restorations use transactions for atomicity
  - **Backup Metadata**: Includes information about the backup contents and creation time
  - **Audit Trail**: Logs all backup and restoration operations
  - **Error Handling**: Comprehensive error handling and reporting
  
  In a real Laravel application:
  - You would implement more sophisticated backup rotation strategies
  - You would add encryption for sensitive backup data
  - You would implement incremental backups for large datasets
  - You would add integration with cloud storage providers
  - You would implement backup verification and integrity checks
challenges:
  - Implement incremental backups to reduce backup size and time
  - Add encryption support for sensitive backup data
  - Create a web interface for managing backups and restorations
  - Implement point-in-time recovery using database transaction logs
  - Add support for backing up and restoring relationships between models
:::
