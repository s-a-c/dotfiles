# Neovim Configuration Backups

This directory contains backup configurations for the Neovim setup.

## Current Backups

- `init.backup-20250810.lua` - Large backup configuration (2,358 lines) from previous setup
  - Contains comprehensive Telescope, plugin, and LSP configurations
  - Moved from root directory to resolve maintenance overhead
  - **Status**: Archived and organized for reference

## Backup Management

### Creating Backups
```bash
# Create timestamped backup before major changes
cp init.lua backups/init-backup-$(date +%Y%m%d-%H%M).lua

# Create configuration snapshot
tar -czf backups/nvim-config-$(date +%Y%m%d).tar.gz lua/ init.lua
```

### Restoring from Backup
```bash
# Restore specific file
cp backups/init-backup-YYYYMMDD-HHMM.lua init.lua

# Restore full configuration
tar -xzf backups/nvim-config-YYYYMMDD.tar.gz
```

## Recommendations

1. **Archive Large Backups**: ✅ Completed - moved init.backup.lua to organized location
2. **Regular Cleanup**: Remove backups older than 6 months
3. **Selective Backup**: Only backup files that have changed
4. **Documentation**: Document what each backup contains and why it was created

## Security

- Never commit API keys or sensitive credentials to backups
- Use environment variables for sensitive configuration
- Regularly audit backup contents for security issues
- Consider encrypting backups containing sensitive data

## Maintenance

- Review backups quarterly and remove outdated ones
- Document significant configuration changes
- Test backup restoration procedures periodically
- Keep backup directory organized and well-documented