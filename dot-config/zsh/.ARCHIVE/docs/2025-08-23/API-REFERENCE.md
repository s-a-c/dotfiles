# ZSH Configuration API Reference

## Table of Contents

1. [Core Functions](#core-functions)
2. [Plugin Management API](#plugin-management-api)
3. [Context-Aware Configuration API](#context-aware-configuration-api)
4. [Async Caching API](#async-caching-api)
5. [Security API](#security-api)
6. [Performance API](#performance-api)
7. [Utility Functions](#utility-functions)

## Core Functions

### Source/Execute Detection
Located in: `00_01-source-execute-detection.zsh`

#### `is_being_executed()`
Detects if the script is being executed directly.
```bash
if is_being_executed; then
    main "$@"
fi
```
**Returns**: 0 if executed, 1 if sourced

#### `is_being_sourced()`
Detects if the script is being sourced.
```bash
if is_being_sourced; then
        zsh_debug_echo "Script was sourced"
fi
```
**Returns**: 0 if sourced, 1 if executed

#### `get_execution_context()`
Returns the execution context as a string.
```bash
context=$(get_execution_context)
echo "Context: $context"
```
**Returns**: "executed", "sourced", or "unknown"

### Standard Helpers
Located in: `00_00-standard-helpers.zsh`

#### `utc_timestamp()`
Generates UTC timestamp for logging.
```bash
timestamp=$(utc_timestamp)
echo "[$timestamp] Event occurred"
```
**Returns**: UTC timestamp string

#### `safe_log(log_file, message, [timestamp])`
Safe logging with directory creation.
```bash
safe_log "/path/to/log" "Message" "$(utc_timestamp)"
```
**Parameters**:
- `log_file`: Path to log file
- `message`: Message to log
- `timestamp`: Optional timestamp (defaults to current)

#### `export_if_unset(var_name, value)`
Exports variable only if not already set.
```bash
export_if_unset "MY_VAR" "default_value"
```

#### `safe_unset(var_name)`
Safely unsets a variable.
```bash
safe_unset "TEMP_VAR"
```

## Plugin Management API

### Plugin Registry
Located in: `20_01-plugin-metadata.zsh`

#### `register_plugin(name, source, type, [dependencies], [conflicts], [description])`
Registers a plugin in the metadata system.
```bash
register_plugin "my-plugin" "user/repo" "github" "git,node" "" "My custom plugin"
```
**Parameters**:
- `name`: Plugin name
- `source`: Plugin source (repo, path, etc.)
- `type`: Plugin type (oh-my-zsh, github, local)
- `dependencies`: Comma-separated list of dependencies
- `conflicts`: Comma-separated list of conflicts
- `description`: Plugin description

#### `get_plugin_metadata(plugin_name)`
Retrieves plugin metadata as JSON.
```bash
metadata=$(get_plugin_metadata "git")
echo "$metadata" | jq '.dependencies'
```
**Returns**: JSON metadata or empty string

#### `list_plugins([format])`
Lists all registered plugins.
```bash
list_plugins simple      # Simple list
list_plugins detailed    # Detailed information
list_plugins json        # JSON format
```

#### `resolve_plugin_load_order(plugins...)`
Resolves plugin load order based on dependencies.
```bash
order=$(resolve_plugin_load_order "plugin1" "plugin2" "plugin3")
```
**Returns**: Space-separated list in load order

### Plugin Validation

#### `validate_plugin_dependencies(plugin_name)`
Validates plugin dependencies are available.
```bash
if validate_plugin_dependencies "my-plugin"; then
        zsh_debug_echo "Dependencies satisfied"
fi
```
**Returns**: 0 if valid, 1 if missing dependencies

#### `check_plugin_conflicts(plugin_name)`
Checks for plugin conflicts.
```bash
if check_plugin_conflicts "my-plugin"; then
        zsh_debug_echo "No conflicts detected"
fi
```
**Returns**: 0 if no conflicts, 1 if conflicts found

## Context-Aware Configuration API

### Context Detection
Located in: `30_35-context-aware-config.zsh`

#### `_detect_directory_context(directory)`
Detects context types for a directory.
```bash
contexts=$(_detect_directory_context "/path/to/project")
echo "Contexts: $contexts"
```
**Returns**: Space-separated list of context types

#### `_find_context_configs(directory)`
Finds applicable context configuration files.
```bash
configs=$(_find_context_configs "/path/to/project")
```
**Returns**: Space-separated list of config files

#### `_apply_context_configuration([directory])`
Applies context configuration for directory.
```bash
_apply_context_configuration "/path/to/project"
```

### Context Management

#### `context-status`
Shows current context status.
```bash
context-status
```
**Output**: Detailed context information

#### `context-reload`
Reloads context configuration.
```bash
context-reload
```

#### `context-create(context_name)`
Creates a new context configuration template.
```bash
context-create "python"
```

## Async Caching API

### Cache Management
Located in: `00_05-async-cache.zsh`

#### `_generate_cache_key(source_file, [cache_type])`
Generates cache key for a file.
```bash
key=$(_generate_cache_key "/path/to/file.zsh" "compiled")
```
**Returns**: SHA-256 based cache key

#### `_is_cache_valid(source_file, cache_file, [ttl])`
Checks if cache is valid.
```bash
if _is_cache_valid "source.zsh" "cache.zwc" 3600; then
        zsh_debug_echo "Cache is valid"
fi
```
**Returns**: 0 if valid, 1 if invalid

#### `_compile_config(source_file, compiled_file)`
Compiles ZSH configuration.
```bash
_compile_config "config.zsh" "config.zwc"
```

#### `_load_compiled_config(source_file)`
Loads compiled configuration with fallback.
```bash
_load_compiled_config "config.zsh"
```

### Async Operations

#### `_async_load_plugin(plugin_name, plugin_source, plugin_type)`
Loads plugin asynchronously.
```bash
_async_load_plugin "my-plugin" "user/repo" "github"
```

#### `_check_async_jobs()`
Checks status of async jobs.
```bash
_check_async_jobs
```

### Cache Commands

#### `cache-status`
Shows cache system status.
```bash
cache-status
```

#### `cache-clean`
Cleans expired cache entries.
```bash
cache-clean
```

#### `cache-rebuild`
Rebuilds entire cache system.
```bash
cache-rebuild
```

## Security API

### Security Auditing
Located in: `00_99-security-check.zsh`

#### `_run_security_audit([output_file])`
Runs comprehensive security audit.
```bash
_run_security_audit "/path/to/report.log"
```

#### `_audit_file_permissions()`
Audits file permissions.
```bash
_audit_file_permissions
```

#### `_audit_environment_variables()`
Audits environment variables for sensitive data.
```bash
_audit_environment_variables
```

### Environment Sanitization
Located in: `00_08-environment-sanitization.zsh`

#### `_sanitize_environment()`
Sanitizes environment variables.
```bash
_sanitize_environment
```

#### `_is_sensitive_variable(var_name)`
Checks if variable contains sensitive data.
```bash
if _is_sensitive_variable "API_KEY"; then
        zsh_debug_echo "Sensitive variable detected"
fi
```

## Performance API

### Performance Monitoring

#### `measure_startup_time([iterations])`
Measures ZSH startup time.
```bash
time=$(measure_startup_time 5)
echo "Startup time: ${time}ms"
```

#### `profile_startup([iterations], [warmup])`
Profiles startup with detailed analysis.
```bash
profile_startup 10 2
```

### Performance Commands

#### `profile`
Full startup profiling.
```bash
profile
```

#### `profile-fast`
Quick 3-iteration profile.
```bash
profile-fast
```

## Utility Functions

### File Operations
Located in: `00_07-utility-functions.zsh`

#### `backup_file(file_path)`
Creates timestamped backup of file.
```bash
backup_file "/path/to/important.conf"
```

#### `safe_mkdir(directory)`
Creates directory with proper permissions.
```bash
safe_mkdir "/path/to/new/dir"
```

### System Information

#### `get_os_info()`
Returns OS information.
```bash
os_info=$(get_os_info)
```

#### `get_shell_info()`
Returns shell information.
```bash
shell_info=$(get_shell_info)
```

### Validation

#### `validate_config_file(file_path)`
Validates ZSH configuration file syntax.
```bash
if validate_config_file "config.zsh"; then
        zsh_debug_echo "Configuration is valid"
fi
```

#### `check_dependencies()`
Checks for required system dependencies.
```bash
check_dependencies
```

## Error Handling

### Standard Error Functions

#### `handle_error(message, [exit_code], [context])`
Standardized error handling.
```bash
handle_error "Something went wrong" 1 "plugin-loading"
```

#### `context_echo(message, [level])`
Context-aware logging.
```bash
context_echo "Debug message" "DEBUG"
context_echo "Error occurred" "ERROR"
```

## Configuration Variables

### Global Configuration
```bash
# Core system
export ZSH_DEBUG=false                    # Debug mode
export ZSH_PROFILE_STARTUP=false         # Profile startup

# Plugin system
export ZSH_PLUGIN_STRICT_DEPENDENCIES=false
export ZSH_PLUGIN_CONFLICT_RESOLUTION="warn"

# Context awareness
export ZSH_CONTEXT_ENABLE=true
export ZSH_CONTEXT_DEBUG=false

# Async caching
export ZSH_ENABLE_ASYNC=true
export ZSH_ENABLE_COMPILATION=true
export ZSH_CACHE_TTL=86400

# Security
export ZSH_ENABLE_SANITIZATION=false
```

## Return Codes

### Standard Return Codes
- `0`: Success
- `1`: General error
- `2`: Warning (non-fatal)
- `124`: Timeout
- `127`: Command not found

### Plugin-Specific Return Codes
- `10`: Plugin not found
- `11`: Dependency missing
- `12`: Conflict detected
- `13`: Invalid metadata

### Context-Specific Return Codes
- `20`: Context not detected
- `21`: Configuration not found
- `22`: Load failed

---

**This API reference covers all major functions and interfaces in the ZSH configuration system. Use these functions to extend and customize your configuration.**
