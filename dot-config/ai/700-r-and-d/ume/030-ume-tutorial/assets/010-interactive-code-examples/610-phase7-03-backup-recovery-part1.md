# Backup and Recovery (Part 1)

:::interactive-code
title: Implementing Robust Backup and Recovery Systems (Part 1)
description: This example demonstrates how to implement comprehensive backup and recovery strategies for Laravel applications with user model enhancements, focusing on database backups and disaster recovery planning.
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
  use Illuminate\Support\Str;
  
  class BackupDatabase extends Command
  {
      /**
       * The name and signature of the console command.
       *
       * @var string
       */
      protected $signature = 'backup:database
                              {--connection=mysql : Database connection to backup}
                              {--tables= : Comma-separated list of tables to backup (default: all)}
                              {--compress : Compress the backup file}
                              {--storage=local : Storage disk to use (local, s3, etc.)}
                              {--path=backups/database : Path within the storage disk}';
      
      /**
       * The console command description.
       *
       * @var string
       */
      protected $description = 'Create a backup of the database';
      
      /**
       * Execute the console command.
       */
      public function handle()
      {
          $connection = $this->option('connection');
          $tables = $this->option('tables');
          $compress = $this->option('compress');
          $storageDisk = $this->option('storage');
          $storagePath = $this->option('path');
          
          $this->info("Starting database backup for connection: {$connection}");
          
          // Validate the connection
          if (!config("database.connections.{$connection}")) {
              $this->error("Database connection '{$connection}' does not exist.");
              return Command::FAILURE;
          }
          
          // Validate the storage disk
          if (!config("filesystems.disks.{$storageDisk}")) {
              $this->error("Storage disk '{$storageDisk}' does not exist.");
              return Command::FAILURE;
          }
          
          try {
              // Generate backup filename
              $timestamp = now()->format('Y-m-d_H-i-s');
              $filename = "backup_{$connection}_{$timestamp}.sql";
              
              // Get tables to backup
              $tablesToBackup = $this->getTablesToBackup($connection, $tables);
              
              if (empty($tablesToBackup)) {
                  $this->error("No tables found to backup.");
                  return Command::FAILURE;
              }
              
              $this->info("Found " . count($tablesToBackup) . " tables to backup.");
              
              // Create temporary directory if it doesn't exist
              $tempDir = storage_path('app/temp');
              if (!File::exists($tempDir)) {
                  File::makeDirectory($tempDir, 0755, true);
              }
              
              $tempFile = "{$tempDir}/{$filename}";
              
              // Create the backup
              $this->createBackup($connection, $tablesToBackup, $tempFile);
              
              // Compress if requested
              if ($compress) {
                  $this->info("Compressing backup file...");
                  $compressedFile = "{$tempFile}.gz";
                  $this->compressFile($tempFile, $compressedFile);
                  $tempFile = $compressedFile;
                  $filename .= '.gz';
              }
              
              // Store the backup
              $this->info("Storing backup to {$storageDisk} disk at {$storagePath}/{$filename}...");
              $backupPath = $this->storeBackup($tempFile, $storageDisk, $storagePath, $filename);
              
              // Clean up temporary files
              File::delete($tempFile);
              
              // Log the backup
              $this->logBackup($connection, $storageDisk, $backupPath, count($tablesToBackup));
              
              $this->info("Database backup completed successfully: {$backupPath}");
              return Command::SUCCESS;
          } catch (\Exception $e) {
              $this->error("Backup failed: " . $e->getMessage());
              Log::error("Database backup failed", [
                  'connection' => $connection,
                  'error' => $e->getMessage(),
                  'trace' => $e->getTraceAsString(),
              ]);
              return Command::FAILURE;
          }
      }
      
      /**
       * Get the list of tables to backup.
       *
       * @param string $connection
       * @param string|null $tables
       * @return array
       */
      protected function getTablesToBackup(string $connection, ?string $tables): array
      {
          if ($tables) {
              return explode(',', $tables);
          }
          
          // Get all tables from the database
          return DB::connection($connection)->getDoctrineSchemaManager()->listTableNames();
      }
      
      /**
       * Create a database backup file.
       *
       * @param string $connection
       * @param array $tables
       * @param string $outputFile
       * @return void
       */
      protected function createBackup(string $connection, array $tables, string $outputFile): void
      {
          $this->info("Creating backup file: {$outputFile}");
          
          $handle = fopen($outputFile, 'w');
          
          // Add header information
          fwrite($handle, "-- Database backup\n");
          fwrite($handle, "-- Generated: " . now()->toDateTimeString() . "\n");
          fwrite($handle, "-- Connection: {$connection}\n");
          fwrite($handle, "-- Tables: " . implode(', ', $tables) . "\n\n");
          
          // Set SQL mode
          fwrite($handle, "SET SQL_MODE = \"NO_AUTO_VALUE_ON_ZERO\";\n");
          fwrite($handle, "SET time_zone = \"+00:00\";\n\n");
          
          // Process each table
          foreach ($tables as $table) {
              $this->backupTable($connection, $table, $handle);
          }
          
          fclose($handle);
      }
      
      /**
       * Backup a single table.
       *
       * @param string $connection
       * @param string $table
       * @param resource $handle
       * @return void
       */
      protected function backupTable(string $connection, string $table, $handle): void
      {
          $this->info("Backing up table: {$table}");
          
          // Get the create table statement
          $createTable = DB::connection($connection)
              ->select("SHOW CREATE TABLE `{$table}`")[0];
              
          $createStatement = $createTable->{'Create Table'} ?? $createTable->{'Create View'};
          
          // Write table structure
          fwrite($handle, "-- Table structure for table `{$table}`\n");
          fwrite($handle, "DROP TABLE IF EXISTS `{$table}`;\n");
          fwrite($handle, "{$createStatement};\n\n");
          
          // Get table data
          $rows = DB::connection($connection)->table($table)->get();
          
          if ($rows->count() > 0) {
              fwrite($handle, "-- Dumping data for table `{$table}`\n");
              fwrite($handle, "INSERT INTO `{$table}` VALUES\n");
              
              $rowCount = $rows->count();
              $rows->each(function ($row, $key) use ($handle, $rowCount) {
                  $values = array_map(function ($value) {
                      if (is_null($value)) {
                          return 'NULL';
                      } elseif (is_numeric($value)) {
                          return $value;
                      } else {
                          return "'" . addslashes($value) . "'";
                      }
                  }, (array) $row);
                  
                  $line = "(" . implode(', ', $values) . ")";
                  
                  // Add comma if not the last row
                  if ($key < $rowCount - 1) {
                      $line .= ",";
                  } else {
                      $line .= ";";
                  }
                  
                  fwrite($handle, $line . "\n");
              });
              
              fwrite($handle, "\n");
          }
          
          fwrite($handle, "-- --------------------------------------------------------\n\n");
      }
      
      /**
       * Compress a file using gzip.
       *
       * @param string $inputFile
       * @param string $outputFile
       * @return void
       */
      protected function compressFile(string $inputFile, string $outputFile): void
      {
          $input = fopen($inputFile, 'rb');
          $output = gzopen($outputFile, 'wb9');
          
          while (!feof($input)) {
              gzwrite($output, fread($input, 1024 * 512));
          }
          
          fclose($input);
          gzclose($output);
          
          // Remove the uncompressed file
          File::delete($inputFile);
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
       * @param string $connection
       * @param string $storageDisk
       * @param string $backupPath
       * @param int $tableCount
       * @return void
       */
      protected function logBackup(string $connection, string $storageDisk, string $backupPath, int $tableCount): void
      {
          Log::info("Database backup created", [
              'connection' => $connection,
              'storage_disk' => $storageDisk,
              'backup_path' => $backupPath,
              'table_count' => $tableCount,
              'size' => Storage::disk($storageDisk)->size($backupPath),
              'created_at' => now()->toDateTimeString(),
          ]);
          
          // Record backup in database
          DB::table('backup_history')->insert([
              'type' => 'database',
              'connection' => $connection,
              'storage_disk' => $storageDisk,
              'path' => $backupPath,
              'size' => Storage::disk($storageDisk)->size($backupPath),
              'table_count' => $tableCount,
              'created_at' => now(),
          ]);
      }
  }
:::
