<?php
/**
 * Backup and Rollback Management System
 * 
 * Provides comprehensive backup creation, verification, and rollback capabilities
 * with timestamped backups and atomic operations for safe file modifications.
 * 
 * @package LinkRectifier\Core
 */

declare(strict_types=1);

namespace LinkRectifier\Core;

use LinkValidator\Utils\Logger;
use LinkValidator\Utils\SecurityValidator;

/**
 * Backup manager for safe file operations
 * 
 * Handles creation of timestamped backups, verification of backup integrity,
 * and rollback operations with comprehensive error handling.
 */
final class BackupManager
{
    private readonly Logger $logger;
    private readonly SecurityValidator $securityValidator;
    
    /**
     * Default backup directory
     */
    private const DEFAULT_BACKUP_DIR = '.ai/backups';
    
    public function __construct(Logger $logger, SecurityValidator $securityValidator)
    {
        $this->logger = $logger;
        $this->securityValidator = $securityValidator;
    }
    
    /**
     * Create a backup of files
     * 
     * @param array<string> $files Files to backup
     * @param string|null $backupDir Backup directory (null for default)
     * @return string Backup ID (timestamp)
     * @throws \RuntimeException If backup creation fails
     */
    public function createBackup(array $files, ?string $backupDir = null): string
    {
        $backupDir = $backupDir ?? self::DEFAULT_BACKUP_DIR;
        $timestamp = date('Y-m-d-H-i-s');
        $backupPath = $backupDir . DIRECTORY_SEPARATOR . $timestamp;
        
        $this->logger->info("Creating backup: {$backupPath}");
        
        // Validate backup directory
        $validatedBackupDir = $this->securityValidator->validatePath($backupDir);
        if ($validatedBackupDir === null) {
            throw new \RuntimeException("Invalid backup directory: {$backupDir}");
        }
        
        // Create backup directory structure
        if (!$this->createBackupDirectory($backupPath)) {
            throw new \RuntimeException("Cannot create backup directory: {$backupPath}");
        }
        
        $backedUpFiles = [];
        $errors = [];
        
        foreach ($files as $file) {
            try {
                $this->backupFile($file, $backupPath);
                $backedUpFiles[] = $file;
                $this->logger->debug("Backed up: {$file}");
            } catch (\Throwable $e) {
                $errors[] = "Failed to backup {$file}: " . $e->getMessage();
                $this->logger->warning("Backup failed for {$file}: " . $e->getMessage());
            }
        }
        
        // Create backup manifest
        $this->createBackupManifest($backupPath, $backedUpFiles, $errors);
        
        if (!empty($errors)) {
            $this->logger->warning(sprintf('Backup completed with %d errors', count($errors)));
        } else {
            $this->logger->info(sprintf('Successfully backed up %d files', count($backedUpFiles)));
        }
        
        return $timestamp;
    }
    
    /**
     * Rollback to a specific backup
     * 
     * @param string $backupId Backup ID (timestamp)
     * @param string|null $backupDir Backup directory (null for default)
     * @return array<string> List of restored files
     * @throws \RuntimeException If rollback fails
     */
    public function rollback(string $backupId, ?string $backupDir = null): array
    {
        $backupDir = $backupDir ?? self::DEFAULT_BACKUP_DIR;
        $backupPath = $backupDir . DIRECTORY_SEPARATOR . $backupId;
        
        $this->logger->info("Rolling back to backup: {$backupPath}");
        
        // Validate backup exists
        if (!is_dir($backupPath)) {
            throw new \RuntimeException("Backup not found: {$backupPath}");
        }
        
        // Load backup manifest
        $manifest = $this->loadBackupManifest($backupPath);
        if ($manifest === null) {
            throw new \RuntimeException("Backup manifest not found or invalid: {$backupPath}");
        }
        
        $restoredFiles = [];
        $errors = [];
        
        foreach ($manifest['files'] as $originalFile) {
            try {
                $this->restoreFile($originalFile, $backupPath);
                $restoredFiles[] = $originalFile;
                $this->logger->debug("Restored: {$originalFile}");
            } catch (\Throwable $e) {
                $errors[] = "Failed to restore {$originalFile}: " . $e->getMessage();
                $this->logger->error("Restore failed for {$originalFile}: " . $e->getMessage());
            }
        }
        
        if (!empty($errors)) {
            throw new \RuntimeException(
                sprintf('Rollback completed with %d errors: %s', count($errors), implode('; ', $errors))
            );
        }
        
        $this->logger->info(sprintf('Successfully restored %d files', count($restoredFiles)));
        
        return $restoredFiles;
    }
    
    /**
     * List available backups
     * 
     * @param string|null $backupDir Backup directory (null for default)
     * @return array<array{id: string, path: string, created: string, files: int}> Backup information
     */
    public function listBackups(?string $backupDir = null): array
    {
        $backupDir = $backupDir ?? self::DEFAULT_BACKUP_DIR;
        
        if (!is_dir($backupDir)) {
            return [];
        }
        
        $backups = [];
        $iterator = new \DirectoryIterator($backupDir);
        
        foreach ($iterator as $item) {
            if ($item->isDot() || !$item->isDir()) {
                continue;
            }
            
            $backupId = $item->getFilename();
            $backupPath = $item->getPathname();
            
            // Validate backup ID format (YYYY-MM-DD-HH-MM-SS)
            if (!preg_match('/^\d{4}-\d{2}-\d{2}-\d{2}-\d{2}-\d{2}$/', $backupId)) {
                continue;
            }
            
            $manifest = $this->loadBackupManifest($backupPath);
            
            $backups[] = [
                'id' => $backupId,
                'path' => $backupPath,
                'created' => $manifest['created'] ?? 'Unknown',
                'files' => count($manifest['files'] ?? []),
            ];
        }
        
        // Sort by creation time (newest first)
        usort($backups, fn($a, $b) => strcmp($b['id'], $a['id']));
        
        return $backups;
    }
    
    /**
     * Delete old backups
     * 
     * @param int $retentionDays Number of days to retain backups
     * @param string|null $backupDir Backup directory (null for default)
     * @return int Number of backups deleted
     */
    public function cleanupOldBackups(int $retentionDays = 30, ?string $backupDir = null): int
    {
        $backupDir = $backupDir ?? self::DEFAULT_BACKUP_DIR;
        $cutoffDate = new \DateTime("-{$retentionDays} days");
        $deleted = 0;
        
        $backups = $this->listBackups($backupDir);
        
        foreach ($backups as $backup) {
            $backupDate = \DateTime::createFromFormat('Y-m-d-H-i-s', $backup['id']);
            
            if ($backupDate && $backupDate < $cutoffDate) {
                try {
                    $this->deleteBackup($backup['id'], $backupDir);
                    $deleted++;
                    $this->logger->debug("Deleted old backup: {$backup['id']}");
                } catch (\Throwable $e) {
                    $this->logger->warning("Failed to delete backup {$backup['id']}: " . $e->getMessage());
                }
            }
        }
        
        if ($deleted > 0) {
            $this->logger->info("Cleaned up {$deleted} old backups");
        }
        
        return $deleted;
    }
    
    /**
     * Verify backup integrity
     * 
     * @param string $backupId Backup ID
     * @param string|null $backupDir Backup directory (null for default)
     * @return array{valid: bool, errors: array<string>} Verification result
     */
    public function verifyBackup(string $backupId, ?string $backupDir = null): array
    {
        $backupDir = $backupDir ?? self::DEFAULT_BACKUP_DIR;
        $backupPath = $backupDir . DIRECTORY_SEPARATOR . $backupId;
        
        $errors = [];
        
        // Check if backup directory exists
        if (!is_dir($backupPath)) {
            $errors[] = "Backup directory not found: {$backupPath}";
            return ['valid' => false, 'errors' => $errors];
        }
        
        // Load and validate manifest
        $manifest = $this->loadBackupManifest($backupPath);
        if ($manifest === null) {
            $errors[] = "Backup manifest not found or invalid";
            return ['valid' => false, 'errors' => $errors];
        }
        
        // Verify each backed up file
        foreach ($manifest['files'] as $originalFile) {
            $backupFile = $this->getBackupFilePath($originalFile, $backupPath);
            
            if (!file_exists($backupFile)) {
                $errors[] = "Backup file missing: {$backupFile}";
            } elseif (!is_readable($backupFile)) {
                $errors[] = "Backup file not readable: {$backupFile}";
            }
        }
        
        return ['valid' => empty($errors), 'errors' => $errors];
    }
    
    /**
     * Create backup directory structure
     * 
     * @param string $backupPath Backup path
     * @return bool True if successful
     */
    private function createBackupDirectory(string $backupPath): bool
    {
        if (is_dir($backupPath)) {
            return true;
        }
        
        return mkdir($backupPath, 0755, true);
    }
    
    /**
     * Backup a single file
     * 
     * @param string $sourceFile Source file path
     * @param string $backupPath Backup directory path
     * @throws \RuntimeException If backup fails
     */
    private function backupFile(string $sourceFile, string $backupPath): void
    {
        if (!file_exists($sourceFile)) {
            throw new \RuntimeException("Source file not found: {$sourceFile}");
        }
        
        $backupFile = $this->getBackupFilePath($sourceFile, $backupPath);
        $backupDir = dirname($backupFile);
        
        // Create backup subdirectory if needed
        if (!is_dir($backupDir)) {
            if (!mkdir($backupDir, 0755, true)) {
                throw new \RuntimeException("Cannot create backup subdirectory: {$backupDir}");
            }
        }
        
        // Copy file with metadata preservation
        if (!copy($sourceFile, $backupFile)) {
            throw new \RuntimeException("Cannot copy file to backup: {$sourceFile} → {$backupFile}");
        }
        
        // Preserve file permissions and timestamps
        $stat = stat($sourceFile);
        if ($stat !== false) {
            chmod($backupFile, $stat['mode'] & 0777);
            touch($backupFile, $stat['mtime'], $stat['atime']);
        }
    }
    
    /**
     * Restore a single file from backup
     * 
     * @param string $originalFile Original file path
     * @param string $backupPath Backup directory path
     * @throws \RuntimeException If restore fails
     */
    private function restoreFile(string $originalFile, string $backupPath): void
    {
        $backupFile = $this->getBackupFilePath($originalFile, $backupPath);
        
        if (!file_exists($backupFile)) {
            throw new \RuntimeException("Backup file not found: {$backupFile}");
        }
        
        $originalDir = dirname($originalFile);
        
        // Create original directory if needed
        if (!is_dir($originalDir)) {
            if (!mkdir($originalDir, 0755, true)) {
                throw new \RuntimeException("Cannot create directory: {$originalDir}");
            }
        }
        
        // Copy file back with metadata preservation
        if (!copy($backupFile, $originalFile)) {
            throw new \RuntimeException("Cannot restore file: {$backupFile} → {$originalFile}");
        }
        
        // Preserve file permissions and timestamps
        $stat = stat($backupFile);
        if ($stat !== false) {
            chmod($originalFile, $stat['mode'] & 0777);
            touch($originalFile, $stat['mtime'], $stat['atime']);
        }
    }
    
    /**
     * Get backup file path for an original file
     * 
     * @param string $originalFile Original file path
     * @param string $backupPath Backup directory path
     * @return string Backup file path
     */
    private function getBackupFilePath(string $originalFile, string $backupPath): string
    {
        // Convert absolute path to relative path within backup
        $relativePath = ltrim(str_replace(getcwd(), '', $originalFile), DIRECTORY_SEPARATOR);
        return $backupPath . DIRECTORY_SEPARATOR . $relativePath;
    }
    
    /**
     * Create backup manifest
     * 
     * @param string $backupPath Backup directory path
     * @param array<string> $files Backed up files
     * @param array<string> $errors Backup errors
     */
    private function createBackupManifest(string $backupPath, array $files, array $errors): void
    {
        $manifest = [
            'created' => date('c'),
            'tool' => 'PHP Link Rectifier',
            'version' => '1.0.0',
            'files' => $files,
            'errors' => $errors,
            'file_count' => count($files),
            'error_count' => count($errors),
        ];
        
        $manifestFile = $backupPath . DIRECTORY_SEPARATOR . 'manifest.json';
        
        if (file_put_contents($manifestFile, json_encode($manifest, JSON_PRETTY_PRINT)) === false) {
            $this->logger->warning("Failed to create backup manifest: {$manifestFile}");
        }
    }
    
    /**
     * Load backup manifest
     * 
     * @param string $backupPath Backup directory path
     * @return array<string, mixed>|null Manifest data or null if not found/invalid
     */
    private function loadBackupManifest(string $backupPath): ?array
    {
        $manifestFile = $backupPath . DIRECTORY_SEPARATOR . 'manifest.json';
        
        if (!file_exists($manifestFile)) {
            return null;
        }
        
        $content = file_get_contents($manifestFile);
        if ($content === false) {
            return null;
        }
        
        $manifest = json_decode($content, true);
        if (json_last_error() !== JSON_ERROR_NONE) {
            return null;
        }
        
        return $manifest;
    }
    
    /**
     * Delete a backup
     * 
     * @param string $backupId Backup ID
     * @param string|null $backupDir Backup directory (null for default)
     * @throws \RuntimeException If deletion fails
     */
    private function deleteBackup(string $backupId, ?string $backupDir = null): void
    {
        $backupDir = $backupDir ?? self::DEFAULT_BACKUP_DIR;
        $backupPath = $backupDir . DIRECTORY_SEPARATOR . $backupId;
        
        if (!is_dir($backupPath)) {
            throw new \RuntimeException("Backup not found: {$backupPath}");
        }
        
        $this->deleteDirectory($backupPath);
    }
    
    /**
     * Recursively delete a directory
     * 
     * @param string $dir Directory to delete
     * @throws \RuntimeException If deletion fails
     */
    private function deleteDirectory(string $dir): void
    {
        $iterator = new \RecursiveIteratorIterator(
            new \RecursiveDirectoryIterator($dir, \RecursiveDirectoryIterator::SKIP_DOTS),
            \RecursiveIteratorIterator::CHILD_FIRST
        );
        
        foreach ($iterator as $file) {
            if ($file->isDir()) {
                if (!rmdir($file->getPathname())) {
                    throw new \RuntimeException("Cannot delete directory: {$file->getPathname()}");
                }
            } else {
                if (!unlink($file->getPathname())) {
                    throw new \RuntimeException("Cannot delete file: {$file->getPathname()}");
                }
            }
        }
        
        if (!rmdir($dir)) {
            throw new \RuntimeException("Cannot delete backup directory: {$dir}");
        }
    }
}
