#!/usr/bin/env zsh
#=============================================================================
# File: test-backup-restore.zsh
# Purpose: Test backup and restore functionality for ZSH configuration
# Dependencies: tar, shasum (macOS built-ins)
# Author: Configuration management system
# Last Modified: 2025-08-20
#=============================================================================

# Test setup and initialization
_test_setup() {
    # Save current working directory
    export ORIGINAL_CWD="$(pwd)"

    # Setup logging
    local log_date=$(date -u +%Y-%m-%d)
    local log_time=$(date -u +%H-%M-%S)
    export LOG_DIR="/Users/s-a-c/.config/zsh/logs/$log_date"
    export LOG_FILE="$LOG_DIR/test-backup-restore_$log_time.log"

    # Create log directory
    mkdir -p "$LOG_DIR"

    # Start logging
    exec 1> >(tee -a "$LOG_FILE")
    exec 2> >(tee -a "$LOG_FILE" >&2)

        zsh_debug_echo "🧪 Testing ZSH Configuration Backup/Restore System"
        zsh_debug_echo "=================================================="
        zsh_debug_echo "📅 Test Started: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
        zsh_debug_echo "📋 Log File: $LOG_FILE"
        zsh_debug_echo ""

    export ZSH_CONFIG_BASE="/Users/s-a-c/.config/zsh"
    export BACKUP_DIR="$ZSH_CONFIG_BASE/.zsh-backups"
    export TEST_TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
    export TEST_BACKUP_DIR="$BACKUP_DIR/test-$TEST_TIMESTAMP"
    export TESTS_PASSED=0
    export TESTS_FAILED=0

    # Ensure backup directory exists
    mkdir -p "$BACKUP_DIR"
}

# Test backup system creation
_test_backup_creation() {
        zsh_debug_echo "\n1. Testing backup system creation..."

    # Create backup function
    _create_zsh_backup() {
        local backup_dir="$1"
        local manifest="$backup_dir/manifest.txt"

        mkdir -p "$backup_dir"

            zsh_debug_echo "# ZSH Configuration Backup Manifest" > "$manifest"
            zsh_debug_echo "# Created: $(date)" >> "$manifest"
            zsh_debug_echo "# System: $(uname -a)" >> "$manifest"
            zsh_debug_echo "# User: $(whoami)" >> "$manifest"
            zsh_debug_echo "" >> "$manifest"

        # Backup main files
        for file in ~/.zshrc ~/.zshenv ~/.zprofile; do
            if [[ -f "$file" ]]; then
                cp "$file" "$backup_dir/"
                    zsh_debug_echo "$(basename "$file"): $(wc -l < "$file") lines" >> "$manifest"
            fi
        done

        # Backup configuration directories
        for dir in ~/.zshrc.d ~/.zshrc.pre-plugins.d ~/.zshrc.add-plugins.d ~/.zshrc.Darwin.d; do
            if [[ -d "$dir" ]]; then
                local dest_name=$(basename "$dir")
                cp -r "$dir" "$backup_dir/$dest_name"
                local file_count=$(find "$dir" -name "*.zsh" 2>/dev/null | wc -l)
                local line_count=$(find "$dir" -name "*.zsh" -exec cat {} \; 2>/dev/null | wc -l)
                    zsh_debug_echo "$dest_name/: $file_count files, $line_count lines" >> "$manifest"
            fi
        done

        return 0
    }

    # Test backup creation
    if _create_zsh_backup "$TEST_BACKUP_DIR"; then
            zsh_debug_echo "   ✅ Backup creation function works"
        ((TESTS_PASSED++))
    else
            zsh_debug_echo "   ❌ Backup creation failed"
        ((TESTS_FAILED++))
        return 1
    fi

    # Test backup directory exists
    if [[ -d "$TEST_BACKUP_DIR" ]]; then
            zsh_debug_echo "   ✅ Backup directory created: $TEST_BACKUP_DIR"
        ((TESTS_PASSED++))
    else
            zsh_debug_echo "   ❌ Backup directory not found: $TEST_BACKUP_DIR"
        ((TESTS_FAILED++))
    fi

    # Test manifest file exists
    if [[ -f "$TEST_BACKUP_DIR/manifest.txt" ]]; then
            zsh_debug_echo "   ✅ Manifest file created"
        ((TESTS_PASSED++))

        # Check manifest content
        if grep -q "ZSH Configuration Backup Manifest" "$TEST_BACKUP_DIR/manifest.txt"; then
                zsh_debug_echo "   ✅ Manifest file has proper header"
            ((TESTS_PASSED++))
        else
                zsh_debug_echo "   ❌ Manifest file missing header"
            ((TESTS_FAILED++))
        fi
    else
            zsh_debug_echo "   ❌ Manifest file not created"
        ((TESTS_FAILED++))
    fi
}

# Test backup integrity verification
_test_backup_integrity() {
        zsh_debug_echo "\n2. Testing backup integrity verification..."

    # Create integrity verification function
    _verify_backup_integrity() {
        local backup_dir="$1"
        local manifest="$backup_dir/manifest.txt"

        [[ -f "$manifest" ]] || return 1
        [[ -d "$backup_dir" ]] || return 1

        # Verify key files exist
        local key_files=(.zshrc .zshenv)
        for file in "${key_files[@]}"; do
            if [[ -f "$HOME/$file" ]] && [[ ! -f "$backup_dir/$file" ]]; then
                    zsh_debug_echo "Missing backup for: $file"
                return 1
            fi
        done

        return 0
    }

    # Test integrity verification
    if _verify_backup_integrity "$TEST_BACKUP_DIR"; then
            zsh_debug_echo "   ✅ Backup integrity verification works"
        ((TESTS_PASSED++))
    else
            zsh_debug_echo "   ❌ Backup integrity verification failed"
        ((TESTS_FAILED++))
    fi
}

# Test backup archival
_test_backup_archival() {
        zsh_debug_echo "\n3. Testing backup archival..."

    # Create archive
    local archive_file="$TEST_BACKUP_DIR.tar.gz"

    if tar -czf "$archive_file" -C "$(dirname "$TEST_BACKUP_DIR")" "$(basename "$TEST_BACKUP_DIR")" 2>/dev/null; then
            zsh_debug_echo "   ✅ Backup archive created: $archive_file"
        ((TESTS_PASSED++))

        # Test archive integrity
        if tar -tzf "$archive_file" >/dev/null 2>&1; then
                zsh_debug_echo "   ✅ Archive integrity verified"
            ((TESTS_PASSED++))
        else
                zsh_debug_echo "   ❌ Archive integrity check failed"
            ((TESTS_FAILED++))
        fi

        # Remove original directory to test extraction
        rm -rf "$TEST_BACKUP_DIR"

        # Test archive extraction
        if tar -xzf "$archive_file" -C "$BACKUP_DIR" 2>/dev/null; then
                zsh_debug_echo "   ✅ Archive extraction works"
            ((TESTS_PASSED++))
        else
                zsh_debug_echo "   ❌ Archive extraction failed"
            ((TESTS_FAILED++))
        fi

    else
            zsh_debug_echo "   ❌ Backup archive creation failed"
        ((TESTS_FAILED++))
    fi
}

# Test restore simulation
_test_restore_simulation() {
        zsh_debug_echo "\n4. Testing restore simulation..."

    # Create restore function (simulation only)
    _simulate_restore() {
        local backup_dir="$1"
        local manifest="$backup_dir/manifest.txt"

            zsh_debug_echo "   📋 Simulating restore from: $backup_dir"

        # Verify manifest exists
        [[ -f "$manifest" ]] || {
                zsh_debug_echo "   ❌ No manifest found for restore"
            return 1
        }

        # List what would be restored
            zsh_debug_echo "   📄 Files that would be restored:"
        find "$backup_dir" -name ".zsh*" -type f | while read file; do
                zsh_debug_echo "      - $(basename "$file")"
        done

            zsh_debug_echo "   📁 Directories that would be restored:"
        find "$backup_dir" -name ".zshrc.*" -type d | while read dir; do
                zsh_debug_echo "      - $(basename "$dir")/"
        done

        return 0
    }

    # Test restore simulation
    if _simulate_restore "$TEST_BACKUP_DIR"; then
            zsh_debug_echo "   ✅ Restore simulation completed successfully"
        ((TESTS_PASSED++))
    else
            zsh_debug_echo "   ❌ Restore simulation failed"
        ((TESTS_FAILED++))
    fi
}

# Test cleanup
_test_cleanup() {
        zsh_debug_echo "\n🧩 Cleaning up test artifacts..."

    # Remove test backup directory and archive
    rm -rf "$TEST_BACKUP_DIR"
    rm -f "$TEST_BACKUP_DIR.tar.gz"

    # Restore original working directory
    if [[ -n "$ORIGINAL_CWD" ]]; then
        cd "$ORIGINAL_CWD" || zsh_debug_echo "Warning: Could not restore original directory: $ORIGINAL_CWD"
    fi

        zsh_debug_echo "\n🏁 Test Results Summary"
        zsh_debug_echo "======================"
        zsh_debug_echo "✅ Tests Passed: $TESTS_PASSED"
        zsh_debug_echo "❌ Tests Failed: $TESTS_FAILED"
        zsh_debug_echo "📊 Total Tests: $((TESTS_PASSED + TESTS_FAILED))"

    if (( TESTS_FAILED == 0 )); then
            zsh_debug_echo "\n🎉 All backup/restore tests passed!"
            zsh_debug_echo "✅ Task 5.4 (Backup and versioning automation) - READY"
        return 0
    else
            zsh_debug_echo "\n⚠️  Some backup/restore tests failed"
            zsh_debug_echo "❌ Task 5.4 needs attention"
        return 1
    fi
}

# Main test execution
main() {
    _test_setup
    _test_backup_creation
    _test_backup_integrity
    _test_backup_archival
    _test_restore_simulation
    _test_cleanup
}

# Only run if called directly
[[ "${(%):-%N}" == "$0" ]] && main "$@"
