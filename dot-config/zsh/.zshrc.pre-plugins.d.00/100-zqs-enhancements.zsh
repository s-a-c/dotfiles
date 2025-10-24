# ZQS Enhancements
# Extensions to the zsh-quickstart-kit functionality

# Override zqs-help to include new commands
function zqs-help-extension() {
  # Call original help function first
  builtin functions -c zqs-help _original_zqs_help
  _original_zqs_help

  # Add our additional help text
  echo ""
  echo "Additional zqs commands:"
  echo "zqs enable-always-show-splash - Always show the startup splash (also on reloads)"
  echo "zqs disable-always-show-splash - Show splash only once per interactive session (default)"
  echo "zqs set-starship-offset VALUE - Set the Starship UTC offset for time module (e.g., +2, -5.5, +0)"
}

# Override the original help function with our extended version
eval "function zqs-help() { zqs-help-extension }"

# Extend the zqs function to handle our new commands
function zqs-extension() {
  # Store the original command
  local cmd="$1"

  case "$cmd" in
  'enable-always-show-splash')
    _zqs-set-setting always-show-splash true
    return 0
    ;;
  'disable-always-show-splash')
    _zqs-set-setting always-show-splash false
    return 0
    ;;
  'set-starship-offset')
    shift
    _zqs-set-setting starship-utc-offset "$1"
    return 0
    ;;
  esac

  # If we get here, it's not one of our commands
  return 1
}

# Hook our extension into the zqs function
function zqs() {
  local cmd="$1"

  # Try our extension first
  zqs-extension "$@" && return

  # If our extension didn't handle it, call the original implementation
  _zqs_original_impl "$@"
}

# Store original implementation for later use
builtin functions -c zqs _zqs_original_impl 2>/dev/null || true
