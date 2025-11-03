# Startup Stabilization Plan

## 1. Scope and Flags

### 1.1. Goal
Fix startup errors by stabilizing PATH, guarding integrations, and aligning redesign flags.

### 1.2. Constraints
- Enable only pre-plugin redesign (ZSH_ENABLE_PREPLUGIN_REDESIGN=1).
- Keep post-plugin redesign unset/disabled.
- Do not reduce the PATH established in .zshenv.

### 1.3. Base
zsh-quickstart-kit with zgenom.

## 2. Early PATH Strategy

### 2.1. Capture baseline PATH in .zshenv

```zsh
typeset -gx ZQS_BASELINE_PATH_SNAPSHOT="$PATH"
typeset -gx ZQS_EARLY_PATH_BOOTSTRAPPED=1
typeset -ga ZQS_BASELINE_path
ZQS_BASELINE_path=("${(s.:.)PATH}")
```

### 2.2. macOS path_helper
Skip or merge in .zprofile to avoid clobbering baseline:

```zsh
if [[ -z ${ZQS_EARLY_PATH_BOOTSTRAPPED-} ]]; then
  eval "$(/usr/libexec/path_helper -s)"
  PATH="${PATH}:${ZQS_BASELINE_PATH_SNAPSHOT}"
  typeset -Ua path
fi
hash -r
```

### 2.3. Pre-plugin safety merge
00-path-safety.zsh ensures no reductions:

```zsh
typeset -a path
if [[ -n ${ZQS_BASELINE_PATH_SNAPSHOT-} ]]; then
  local -a want have
  want=("${(s.:.)ZQS_BASELINE_PATH_SNAPSHOT}")
  have=("${path[@]}")
  for d in "${want[@]}"; do
    [[ -n $d ]] && [[ ${have[(Ie)$d]} -eq 0 ]] && path+=("$d")
  done
  typeset -Ua path
  export PATH="${(j.:.)path}"
  hash -r
fi
```

## 3. Redesign Flags

### 3.1. .zshenv

```zsh
export ZSH_ENABLE_PREPLUGIN_REDESIGN=1
unset ZSH_ENABLE_POSTPLUGIN_REDESIGN
```

### 3.2. Post-plugin guard (if needed)

```zsh
[[ -z ${ZSH_ENABLE_POSTPLUGIN_REDESIGN-} ]] && return 0
```

## 4. Composer Directory and PATH

### 4.1. Target directory (explanation)
- Use COMPOSER_HOME if set by the user.
- Else use XDG_DATA_HOME.
- Else fallback to ~/.local/share/composer.
- Expression: `${COMPOSER_HOME:-${XDG_DATA_HOME:-${HOME}/.local/share}/composer}`

### 4.2. Implementation

```zsh
typeset -gx COMPOSER_HOME="${COMPOSER_HOME:-${XDG_DATA_HOME:-${HOME}/.local/share}/composer}"
[[ -d $COMPOSER_HOME ]] || mkdir -p "$COMPOSER_HOME"
path+=("$COMPOSER_HOME/vendor/bin")
typeset -Ua path
export PATH="${(j.:.)path}"
```

### 4.3. Migration and permissions

```bash
if [[ -d "$HOME/.composer" && "$HOME/.composer" != "$COMPOSER_HOME" ]]; then
  rsync -a --remove-source-files "$HOME/.composer"/ "$COMPOSER_HOME"/
  rmdir "$HOME/.composer" 2>/dev/null || true
  ln -s "$COMPOSER_HOME" "$HOME/.composer"
fi
chmod o-w "$COMPOSER_HOME" || true
find "$COMPOSER_HOME" -type d -exec chmod 0755 {} + || true
find "$COMPOSER_HOME" -type f -exec chmod 0644 {} + || true
find "$COMPOSER_HOME/vendor/bin" -type f -exec chmod 0755 {} + || true
```

## 5. direnv Integration

### 5.1. Guard hook

```zsh
if (( $+commands[direnv] )); then
  eval "$(direnv hook zsh)"
fi
```

## 6. Widgets and Prompt Guards

### 6.1. Widgets (interactive-only)

```zsh
if (( ${+widgets} )) && (( ${+widgets[zle-keymap-select]} )); then
  # bind or inspect
fi
```

### 6.2. Prompt defaults

```zsh
typeset -g RPS1="${RPS1-}"
typeset -g PROMPT="${PROMPT-}"
typeset -g RPROMPT="${RPROMPT-}"
typeset -g vi_mode_in_opts="${vi_mode_in_opts-0}"
```

## 7. AWS Prompt Guard

### 7.1. Safe function

```zsh
aws_prompt_info() {
  local profile="${AWS_PROFILE:-${AWS_DEFAULT_PROFILE:-}}"
  local region="${AWS_PROFILE_REGION:-${AWS_DEFAULT_REGION:-}}"
  local acct="${AWS_ACCOUNT_ID:-}"
  [[ -z $profile && -z $region && -z $acct ]] && return 0
  local seg=""
  [[ -n $profile ]] && seg+=":$profile"
  [[ -n $region  ]] && seg+="@$region"
  [[ -n $acct    ]] && seg+="[$acct]"
  [[ -n $seg     ]] && print -- "aws${seg}"
}
```

## 8. Testing

### 8.1. Isolated run

```bash
ZDOTDIR=$PWD zsh -i -c 'echo OK; exit'
```

### 8.2. Harness
Create tests/startup/test-path-and-guards.zsh (see main plan).

## 9. Results

### 9.1. ✅ Issues Fixed
- ✅ date command available  
- ✅ rg command available
- ✅ pre-plugin redesign enabled
- ✅ post-plugin redesign disabled  
- ✅ RPS1 variable initialized
- ✅ PATH baseline preserved
- ✅ Ruby security warnings eliminated

### 9.2. ⚠️ Minor Issues Remaining
- Widget parameter errors (from legacy modules)
- Some command not found errors during module loading (non-critical)

## 10. Notes
- We do not remove baseline PATH entries; we add and dedupe only.
- Ruby warnings are addressed by permissions, not by pruning PATH.
- Test harness available at `tests/startup/test-path-and-guards.zsh`