#!/usr/bin/env zsh

# Test the recursive loading function
function load-shell-fragments() {
  if [[ -z $1 ]]; then
<<<<<<< HEAD
        zf::debug "You must give load-shell-fragments a directory path"
=======
        zsh_debug_echo "You must give load-shell-fragments a directory path"
>>>>>>> origin/develop
  else
    if [[ -d "$1" ]]; then
      if [ -n "$(/bin/ls -A $1)" ]; then
        # Check if directory contains .zsh files directly
        setopt NULL_GLOB
        local direct_files=($1/*.zsh)
        unsetopt NULL_GLOB
        if [[ ${#direct_files[@]} -gt 0 && -f "${direct_files[1]}" ]]; then
          # Load direct .zsh files first (old behavior)
<<<<<<< HEAD
              zf::debug "Loading direct .zsh files from $1:"
          for _zqs_fragment in $(/bin/ls -A $1)
          do
            if [ -r $1/$_zqs_fragment ] && [[ "$_zqs_fragment" == *.zsh ]]; then
                  zf::debug "  Would load: $1/$_zqs_fragment"
=======
              zsh_debug_echo "Loading direct .zsh files from $1:"
          for _zqs_fragment in $(/bin/ls -A $1)
          do
            if [ -r $1/$_zqs_fragment ] && [[ "$_zqs_fragment" == *.zsh ]]; then
                  zsh_debug_echo "  Would load: $1/$_zqs_fragment"
>>>>>>> origin/develop
            fi
          done
        else
          # No direct .zsh files, look for subdirectories with .zsh files (new behavior)
<<<<<<< HEAD
              zf::debug "No direct .zsh files found, loading recursively from $1:"
=======
              zsh_debug_echo "No direct .zsh files found, loading recursively from $1:"
>>>>>>> origin/develop
          local zsh_files
          zsh_files=($(find "$1" -name "*.zsh" -type f | sort))
          for _zqs_fragment in "${zsh_files[@]}"
          do
            if [ -r "$_zqs_fragment" ]; then
<<<<<<< HEAD
                  zf::debug "  Would load: $_zqs_fragment"
=======
                  zsh_debug_echo "  Would load: $_zqs_fragment"
>>>>>>> origin/develop
            fi
          done
        fi
        unset _zqs_fragment direct_files zsh_files
      fi
    else
<<<<<<< HEAD
          zf::debug "$1 is not a directory"
=======
          zsh_debug_echo "$1 is not a directory"
>>>>>>> origin/develop
    fi
  fi
}

echo "=== Testing recursive load-shell-fragments ==="
echo "Testing .zshrc.pre-plugins.d:"
load-shell-fragments ".zshrc.pre-plugins.d"

echo -e "\nTesting .zshrc.d:"
load-shell-fragments ".zshrc.d"
