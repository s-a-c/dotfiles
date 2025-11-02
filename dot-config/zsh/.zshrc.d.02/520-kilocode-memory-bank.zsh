#!/usr/bin/env zsh
# Filename: 520-kilocode-memory-bank.zsh
# Purpose:  KiloCode Memory Bank System
# Phase:    Post-plugin (.zshrc.d/)

export KILOCODE_CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/kilocode/config.json"

# Function to get a configuration value
get_kilocode_config() {
  local key="$1"
  jq -r --arg key "$key" '.[$key]' "$KILOCODE_CONFIG_FILE" 2>/dev/null
}

# Function to set a configuration value
set_kilocode_config() {
  local key="$1"
  local value="$2"
  jq --arg key "$key" --arg value "$value" '.[$key] = $value' "$KILOCODE_CONFIG_FILE" > "$KILOCODE_CONFIG_FILE.tmp" && mv "$KILOCODE_CONFIG_FILE.tmp" "$KILOCODE_CONFIG_FILE"
}

# Define the base directory for snippets using XDG Base Directory Specification
export KILOCODE_SNIPPETS_DIR=$(get_kilocode_config "snippets_dir" || echo "${XDG_DATA_HOME:-$HOME/.local/share}/kilocode/snippets")

# Define cache file for metadata
export KILOCODE_CACHE_FILE=$(get_kilocode_config "cache_file" || echo "${XDG_CACHE_HOME:-$HOME/.cache}/kilocode/metadata_cache.json")

# Function to get the effective snippets directory (following symlinks)
get_snippets_dir() {
  if [[ -L "$KILOCODE_SNIPPETS_DIR" ]]; then
    # Use readlink -f to follow all symlinks and get the actual directory
    readlink -f "$KILOCODE_SNIPPETS_DIR" 2>/dev/null || readlink "$KILOCODE_SNIPPETS_DIR"
  else
    echo "$KILOCODE_SNIPPETS_DIR"
  fi
}

# Function to initialize the memory bank system
init_kilocode_memory_bank() {
  # Ensure config directory exists
  local config_dir=$(dirname "$KILOCODE_CONFIG_FILE")
  if [[ ! -d "$config_dir" ]]; then
    mkdir -p "$config_dir"
  fi

  # Create default config if it doesn't exist
  if [[ ! -f "$KILOCODE_CONFIG_FILE" ]]; then
    echo "{}" > "$KILOCODE_CONFIG_FILE"
    set_kilocode_config "snippets_dir" "${XDG_DATA_HOME:-$HOME/.local/share}/kilocode/snippets"
    set_kilocode_config "cache_file" "${XDG_CACHE_HOME:-$HOME/.cache}/kilocode/metadata_cache.json"
  fi

  local snippets_dir=$(get_snippets_dir)

  # Ensure the directory exists
  if [[ ! -d "$snippets_dir" ]]; then
    mkdir -p "$snippets_dir"
    echo "KiloCode Memory Bank initialized at $snippets_dir"
  fi

  # Initialize Git repository if it doesn't exist
  if [[ ! -d "$snippets_dir/.git" ]]; then
    (
      cd "$snippets_dir"
      git init
      echo ".index.json" > .gitignore
      echo ".index.json.tmp" >> .gitignore
      git add .gitignore
      git commit -m "Initial commit: Initialize KiloCode Memory Bank"
    )
    echo "Git repository initialized for KiloCode Memory Bank"
  fi

  # Ensure cache directory exists
  local cache_dir=$(dirname "$KILOCODE_CACHE_FILE")
  if [[ ! -d "$cache_dir" ]]; then
    mkdir -p "$cache_dir"
  fi

  # Create or update the centralized index file
  update_centralized_index
}

# Function to automatically commit changes
_kilocode_git_commit() {
  local snippets_dir=$(get_snippets_dir)
  local message="$1"
  local file_path="$2"

  (
    cd "$snippets_dir"
    git add "$file_path"
    [[ -f "${file_path}.json" ]] && git add "${file_path}.json"
    git commit -m "$message"
  )
}

# Function to create a new branch
_kilocode_git_branch() {
  local snippets_dir=$(get_snippets_dir)
  local branch_name="$1"

  if [[ -z "$branch_name" ]]; then
    echo "Usage: kbranch <branch-name>"
    return 1
  fi

  (
    cd "$snippets_dir"
    git checkout -b "$branch_name"
  )
}

# Function to create a new tag
_kilocode_git_tag() {
  local snippets_dir=$(get_snippets_dir)
  local tag_name="$1"
  local message="$2"

  if [[ -z "$tag_name" ]]; then
    echo "Usage: ktag <tag-name> [message]"
    return 1
  fi

  (
    cd "$snippets_dir"
    if [[ -n "$message" ]]; then
      git tag -a "$tag_name" -m "$message"
    else
      git tag "$tag_name"
    fi
  )
}

# Function to push changes to a remote repository
_kilocode_git_push() {
  local snippets_dir=$(get_snippets_dir)
  (
    cd "$snippets_dir"
    git push
  )
}

# Function to pull changes from a remote repository
_kilocode_git_pull() {
  local snippets_dir=$(get_snippets_dir)
  (
    cd "$snippets_dir"
    git pull
  )
}

# Function to resolve conflicts (placeholder)
_kilocode_git_resolve_conflicts() {
  echo "Conflict resolution not yet implemented."
}

# Function to create/update centralized index file
update_centralized_index() {
  local snippets_dir=$(get_snippets_dir)
  local index_file="$snippets_dir/.index.json"

  # Create empty JSON object if index file doesn't exist
  if [[ ! -f "$index_file" ]]; then
    echo "{}" > "$index_file"
  fi

  # Process all metadata files
  find "$snippets_dir" -name "*.json" -not -path "$index_file" | while read -r metadata_file; do
    local snippet_file=${metadata_file%.json}
    # Only process if corresponding snippet file exists
    if [[ -f "$snippet_file" ]]; then
      local rel_path=${snippet_file#$snippets_dir/}
      # Extract metadata and add to index
      local tags=$(jq -r '.tags | join(",")' "$metadata_file" 2>/dev/null || echo "")
      local categories=$(jq -r '.categories | join(",")' "$metadata_file" 2>/dev/null || echo "")
      local creation_date=$(jq -r '.creation_date' "$metadata_file" 2>/dev/null || "")
      local author=$(jq -r '.author' "$metadata_file" 2>/dev/null || "")
      local usage_frequency=$(jq -r '.usage_frequency' "$metadata_file" 2>/dev/null || "0")
      local description=$(jq -r '.description' "$metadata_file" 2>/dev/null || "")

      # Extract content for full-text search
      local content=$(cat "$snippet_file" 2>/dev/null | tr '\n' ' ' | sed 's/"/\\"/g')

      # Update index file with snippet metadata
      jq --arg path "$rel_path" \
         --arg tags "$tags" \
         --arg categories "$categories" \
         --arg creation_date "$creation_date" \
         --arg author "$author" \
         --arg usage_frequency "$usage_frequency" \
         --arg description "$description" \
         --arg content "$content" \
         '.[$path] = {
           "tags": ($tags | split(",") | map(select(length > 0))),
           "categories": ($categories | split(",") | map(select(length > 0))),
           "creation_date": $creation_date,
           "author": $author,
           "usage_frequency": ($usage_frequency | tonumber),
           "description": $description,
           "content": $content
         }' "$index_file" > "$index_file.tmp" && mv "$index_file.tmp" "$index_file"
    fi
  done
}

# Function to cache metadata for a snippet
cache_metadata() {
  local snippet_name="$1"
  local snippets_dir=$(get_snippets_dir)
  local metadata_file="$snippets_dir/${snippet_name}.json"
  local index_file="$snippets_dir/.index.json"

  # Check if metadata file exists
  if [[ -f "$metadata_file" ]]; then
    # Extract metadata from index file
    local metadata=$(jq -r --arg name "$snippet_name" '.[$name]' "$index_file" 2>/dev/null)

    # If metadata exists in index, cache it
    if [[ -n "$metadata" && "$metadata" != "null" ]]; then
      # Create or update cache entry
      jq --arg name "$snippet_name" \
         --argjson metadata "$metadata" \
         '.[$name] = $metadata' "$KILOCODE_CACHE_FILE" > "$KILOCODE_CACHE_FILE.tmp" && mv "$KILOCODE_CACHE_FILE.tmp" "$KILOCODE_CACHE_FILE"
    fi
  fi
}

# Function to get cached metadata for a snippet
get_cached_metadata() {
  local snippet_name="$1"

  # Check if cache file exists
  if [[ -f "$KILOCODE_CACHE_FILE" ]]; then
    # Get metadata from cache
    jq -r --arg name "$snippet_name" '.[$name]' "$KILOCODE_CACHE_FILE" 2>/dev/null
  fi
}

# Function to clear metadata cache
clear_metadata_cache() {
  if [[ -f "$KILOCODE_CACHE_FILE" ]]; then
    rm "$KILOCODE_CACHE_FILE"
    echo "Metadata cache cleared"
  else
    echo "No metadata cache found"
  fi
}

# Function to save a code snippet with metadata
save_snippet() {
  local name="$1"
  local category="$2"
  local tags="$3"
  local description="${4:-No description provided}"  # Default description if not provided

  # Create the directory if it doesn't exist
  mkdir -p "${KILOCODE_SNIPPETS_DIR}/${category}"

  # Save the snippet content
  local snippet_file="${KILOCODE_SNIPPETS_DIR}/${name}"
  cat > "${snippet_file}"

  # Create metadata file
  local metadata_file="${KILOCODE_SNIPPETS_DIR}/${name}.json"
  local creation_date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  local author=$(whoami)

  # Process tags into JSON array
  local tags_json=""
  if [[ -n "$tags" ]]; then
    local tag_array=()
    IFS=',' read -rA tag_array <<< "$tags"
    for tag in "${tag_array[@]}"; do
      tag=$(echo "$tag" | xargs)  # Trim whitespace
      if [[ -n "$tags_json" ]]; then
        tags_json="${tags_json}, \"$tag\""
      else
        tags_json="\"$tag\""
      fi
    done
    tags_json="[$tags_json]"
  else
    tags_json="[]"
  fi

  # Write metadata to JSON file
  cat > "${metadata_file}" <<EOF
{
  "tags": ${tags_json},
  "categories": ["${category}"],
  "creation_date": "${creation_date}",
  "author": "${author}",
  "usage_frequency": 0,
  "description": "${description}"
}
EOF

  echo "Snippet '$name' saved in category '$category'"

  # Commit the changes
  _kilocode_git_commit "feat: add snippet '$name'" "$name"

  # Update centralized index
  update_centralized_index
}

# Function to list all snippets
list_snippets() {
  local snippets_dir=$(get_snippets_dir)

  if [[ ! -d "$snippets_dir" ]]; then
    echo "KiloCode Memory Bank is not initialized"
    return 1
  fi

  echo "Available snippets:"
  local found_snippets=0

  # Find all files that are not JSON metadata files and not in hidden directories
  while IFS= read -r file; do
    # Get relative path from snippets_dir and remove leading ./
    local rel_path=${file#./}
    # Only show files that don't have a .json extension
    if [[ "${file##*.}" != "json" ]]; then
      echo "  $rel_path"
      found_snippets=1
    fi
  done < <(cd "$snippets_dir" && find . -type f -not -name "*.json" -not -path "./.*/*")

  # Handle the case where no files are found
  if [[ $found_snippets -eq 0 ]]; then
    echo "  No snippets found"
  fi
}

# Function to retrieve a snippet
get_snippet() {
  local name="$1"

  if [[ -z "$name" ]]; then
    echo "Usage: get_snippet <name>"
    return 1
  fi

  local snippets_dir=$(get_snippets_dir)
  local file_path="$snippets_dir/$name"

  if [[ -f "$file_path" ]]; then
    cat "$file_path"

    # Update usage frequency
    local metadata_path="$file_path.json"
    if [[ -f "$metadata_path" ]]; then
      local temp_file=$(mktemp)
      jq '.usage_frequency += 1' "$metadata_path" > "$temp_file" && mv "$temp_file" "$metadata_path"

      # Update centralized index
      update_centralized_index
    fi
  else
    echo "Snippet '$name' not found"
    return 1
  fi
}

# Function to highlight search results
highlight_results() {
  local query="$1"
  local input="$2"
  echo "$input" | grep --color=always -E "$query|$"
}

# Function to search for snippets by tag, category, or content
search_snippets() {
  local query="$1"

  if [[ -z "$query" ]]; then
    echo "Usage: search_snippets <query>"
    return 1
  fi

  local snippets_dir=$(get_snippets_dir)
  local index_file="$snippets_dir/.index.json"

  echo "Search results for '$query':"

  # Use the centralized index for searching
  if [[ -f "$index_file" ]]; then
    # Search in tags, categories, description, and content, and sort by usage_frequency
    jq -r --arg query "$query" '
      to_entries[] |
      select(.value.tags[]? == $query or
             .value.categories[]? == $query or
             .value.description? and (.value.description | test($query; "i")) or
             .value.content? and (.value.content | test($query; "i"))) |
      "\(.value.usage_frequency // 0) \(.key)"
    ' "$index_file" | sort -rn | sed 's/^[0-9]* //' | while read -r snippet; do
      highlight_results "$query" "  $snippet"
    done
  else
    # Fallback to the original search method if index doesn't exist
    find "$snippets_dir" -name "*.json" -exec grep -l "$query" {} \; | while read -r metadata_file; do
      local snippet_file=${metadata_file%.json}
      if [[ -f "$snippet_file" ]]; then
        local rel_path=${snippet_file#$snippets_dir/}
        highlight_results "$query" "  $rel_path"
      fi
    done
  fi
}

# Function to search snippets by tag
search_by_tag() {
  local tag="$1"

  if [[ -z "$tag" ]]; then
    echo "Usage: search_by_tag <tag>"
    return 1
  fi

  local snippets_dir=$(get_snippets_dir)
  local index_file="$snippets_dir/.index.json"

  echo "Snippets tagged with '$tag':"

  if [[ -f "$index_file" ]]; then
    jq -r --arg tag "$tag" '
      to_entries[] |
      select(.value.tags[]? == $tag) |
      .key
    ' "$index_file" | while read -r snippet; do
      echo "  $snippet"
    done
  else
    echo "  No index file found"
  fi
}

# Function to search snippets by category
search_by_category() {
  local category="$1"

  if [[ -z "$category" ]]; then
    echo "Usage: search_by_category <category>"
    return 1
  fi

  local snippets_dir=$(get_snippets_dir)
  local index_file="$snippets_dir/.index.json"

  echo "Snippets in category '$category':"

  if [[ -f "$index_file" ]]; then
    jq -r --arg category "$category" '
      to_entries[] |
      select(.value.categories[]? == $category) |
      .key
    ' "$index_file" | while read -r snippet; do
      echo "  $snippet"
    done
  else
    echo "  No index file found"
  fi
}

# Function to search snippets by content
search_by_content() {
  local query="$1"

  if [[ -z "$query" ]]; then
    echo "Usage: search_by_content <query>"
    return 1
  fi

  local snippets_dir=$(get_snippets_dir)
  local index_file="$snippets_dir/.index.json"

  echo "Snippets containing '$query':"

  if [[ -f "$index_file" ]]; then
    jq -r --arg query "$query" '
      to_entries[] |
      select(.value.content? and (.value.content | test($query; "i"))) |
      .key
    ' "$index_file" | while read -r snippet; do
      echo "  $snippet"
    done
  else
    echo "  No index file found"
  fi
}

# Function to search by tags and content
search_by_tags_and_content() {
  local tags_csv="$1"
  local query="$2"

  if [[ -z "$tags_csv" || -z "$query" ]]; then
    echo "Usage: search_by_tags_and_content <tags_csv> <query>"
    return 1
  fi

  local snippets_dir=$(get_snippets_dir)
  local index_file="$snippets_dir/.index.json"

  echo "Search results for snippets tagged with '$tags_csv' containing '$query':"

  if [[ -f "$index_file" ]]; then
    jq -r --arg tags_csv "$tags_csv" --arg query "$query" '
      to_entries[] |
      select(
        (.value.tags | join(",")) as $snippet_tags |
        ($tags_csv | split(",") | all(test_tag -> $snippet_tags | contains(test_tag))) and
        (.value.content? and (.value.content | test($query; "i")))
      ) |
      "\(.value.usage_frequency // 0) \(.key)"
    ' "$index_file" | sort -rn | sed 's/^[0-9]* //' | while read -r snippet; do
      highlight_results "$query" "  $snippet"
    done
  else
    echo "  No index file found"
  fi
}

# Function to calculate Levenshtein distance between two strings
levenshtein_distance() {
  local s1="$1"
  local s2="$2"
  local len1=${#s1}
  local len2=${#s2}
  local d=()

  for ((i=0; i<=len1; i++)); do
    d[$i,0]=$i
  done

  for ((j=0; j<=len2; j++)); do
    d[0,$j]=$j
  done

  for ((i=1; i<=len1; i++)); do
    for ((j=1; j<=len2; j++)); do
      local cost=0
      if [[ "${s1:$i-1:1}" != "${s2:$j-1:1}" ]]; then
        cost=1
      fi

      local above=${d[$i-1,$j]}
      local left=${d[$i,$j-1]}
      local diag=${d[$i-1,$j-1]}

      d[$i,$j]=$(( above + 1 ))
      [[ $(( left + 1 )) -lt ${d[$i,$j]} ]] && d[$i,$j]=$(( left + 1 ))
      [[ $(( diag + cost )) -lt ${d[$i,$j]} ]] && d[$i,$j]=$(( diag + cost ))
    done
  done

  echo ${d[$len1,$len2]}
}

# Function for fuzzy search
fuzzy_search_snippets() {
  local query="$1"
  local tolerance="${2:-2}" # Default tolerance of 2

  if [[ -z "$query" ]]; then
    echo "Usage: fuzzy_search_snippets <query> [tolerance]"
    return 1
  fi

  local snippets_dir=$(get_snippets_dir)
  local index_file="$snippets_dir/.index.json"

  echo "Fuzzy search results for '$query' (tolerance: $tolerance):"

  if [[ -f "$index_file" ]]; then
    jq -r 'to_entries[] | .key' "$index_file" | while read -r snippet; do
      local distance=$(levenshtein_distance "$query" "$snippet")
      if [[ $distance -le $tolerance ]]; then
        local usage_frequency=$(jq -r --arg key "$snippet" '.[$key].usage_frequency // 0' "$index_file")
        echo "$usage_frequency $distance $snippet"
      fi
    done | sort -rn -k1,1 -k2,2n | sed 's/^[0-9]* [0-9]* //' | while read -r result; do
      highlight_results "$query" "  $result"
    done
  else
    echo "  No index file found"
  fi
}

# Function for combined search (tags + fuzzy)
combined_search() {
  local tags_csv="$1"
  local query="$2"
  local tolerance="${3:-2}" # Default tolerance of 2

  if [[ -z "$tags_csv" || -z "$query" ]]; then
    echo "Usage: combined_search <tags_csv> <query> [tolerance]"
    return 1
  fi

  local snippets_dir=$(get_snippets_dir)
  local index_file="$snippets_dir/.index.json"

  echo "Combined search for snippets tagged with '$tags_csv' and fuzzy search for '$query' (tolerance: $tolerance):"

  if [[ -f "$index_file" ]]; then
    jq -r --arg tags_csv "$tags_csv" '
      to_entries[] |
      select(
        (.value.tags | join(",")) as $snippet_tags |
        ($tags_csv | split(",") | all(test_tag -> $snippet_tags | contains(test_tag)))
      ) |
      .key
    ' "$index_file" | while read -r snippet; do
      local distance=$(levenshtein_distance "$query" "$snippet")
      if [[ $distance -le $tolerance ]]; then
        local usage_frequency=$(jq -r --arg key "$snippet" '.[$key].usage_frequency // 0' "$index_file")
        echo "$usage_frequency $distance $snippet"
      fi
    done | sort -rn -k1,1 -k2,2n | sed 's/^[0-9]* [0-9]* //' | while read -r result; do
      highlight_results "$query" "  $result"
    done
  else
    echo "  No index file found"
  fi
}

# Function to delete a snippet
delete_snippet() {
  local name="$1"

  if [[ -z "$name" ]]; then
    echo "Usage: delete_snippet <name>"
    return 1
  fi

  local snippets_dir=$(get_snippets_dir)
  local file_path="$snippets_dir/$name"
  local metadata_path="$file_path.json"

  if [[ -f "$file_path" ]]; then
    rm "$file_path"
    [[ -f "$metadata_path" ]] && rm "$metadata_path"
    echo "Snippet '$name' deleted"

    # Commit the deletion
    _kilocode_git_commit "fix: delete snippet '$name'" "$name"

    # Update centralized index
    update_centralized_index
  else
    echo "Snippet '$name' not found"
    return 1
  fi
}

# Function to show snippet metadata
info_snippet() {
  local name="$1"

  if [[ -z "$name" ]]; then
    echo "Usage: info_snippet <name>"
    return 1
  fi

  local snippets_dir=$(get_snippets_dir)
  local file_path="$snippets_dir/$name"
  local metadata_path="$file_path.json"

  # Try to get metadata from cache first
  local cached_metadata=$(get_cached_metadata "$name")

  if [[ -n "$cached_metadata" && "$cached_metadata" != "null" ]]; then
    echo "$cached_metadata" | jq '.'
    return 0
  fi

  # If not in cache, get from metadata file
  if [[ -f "$metadata_path" ]]; then
    cat "$metadata_path" | jq '.'
    # Cache the metadata for future use
    cache_metadata "$name"
  else
    echo "No metadata found for snippet '$name'"
    return 1
  fi
}

# Function to handle configuration management
_kilocode_config() {
  local action="$1"
  local key="$2"
  local value="$3"

  case "$action" in
    get)
      get_kilocode_config "$key"
      ;;
    set)
      set_kilocode_config "$key" "$value"
      echo "Configuration updated: $key = $value"
      ;;
    list)
      jq '.' "$KILOCODE_CONFIG_FILE"
      ;;
    *)
      echo "Usage: kilocode config <get|set|list> [key] [value]"
      return 1
      ;;
  esac
}

# Function to display help information
_kilocode_help() {
  echo "KiloCode Memory Bank System"
  echo ""
  echo "A powerful command-line interface for managing your code snippets."
  echo ""
  echo "USAGE:"
  echo "  kilocode <command> [arguments]"
  echo ""
  echo "COMMANDS:"
  echo "  Core:"
  echo "    save [name] [category] [tags] [description]   Save a snippet (interactive if no args)"
  echo "    get <name>                                    Retrieve a snippet to stdout"
  echo "    list                                          List all snippets"
  echo "    delete <name>                                 Delete a snippet"
  echo "    info <name>                                   Show snippet metadata"
  echo ""
  echo "  Search:"
  echo "    search <query>                                General search (tags, categories, content)"
  echo "    searchtag <tag>                               Search by a specific tag"
  echo "    searchcat <category>                          Search by a specific category"
  echo "    searchcontent <query>                         Search only within snippet content"
  echo "    fuzzy <query> [tolerance]                     Fuzzy search by snippet name"
  echo "    filter <tags_csv> <query>                     Filter by tags, then search content"
  echo "    combo <tags_csv> <query> [tolerance]          Filter by tags, then fuzzy search"
  echo ""
  echo "  Versioning (Git):"
  echo "    branch <branch-name>                          Create a new branch"
  echo "    tag <tag-name> [message]                      Create a new tag"
  echo "    push                                          Push changes to a remote repository"
  echo "    pull                                          Pull changes from a remote repository"
  echo "    resolve                                       (Placeholder) Resolve merge conflicts"
  echo ""
  echo "  System:"
  echo "    config <get|set|list> [key] [value]           Manage configuration"
  echo "    clearcache                                    Clear the metadata cache"
  echo "    help, --help, -h                              Show this help message"
  echo ""
  echo "EXAMPLES:"
  echo "  # Save a snippet interactively"
  echo "  kilocode save"
  echo ""
  echo "  # Save a snippet from a pipe"
  echo "  echo 'echo \"Hello, World!\"' | kilocode save hello_world shell bash,hello \"A simple hello world script\""
  echo ""
  echo "  # Get a snippet"
  echo "  kilocode get hello_world"
  echo ""
  echo "  # Search for snippets"
  echo "  kilocode search hello"
}

# Function to display statistics
_kilocode_stats() {
  local snippets_dir=$(get_snippets_dir)
  local index_file="$snippets_dir/.index.json"

  if [[ ! -f "$index_file" ]]; then
    echo "No index file found. Please run 'kilocode save' or 'kilocode list' to generate it."
    return 1
  fi

  local total_snippets=$(jq 'length' "$index_file")
  local total_tags=$(jq '[.[] | .tags[]] | unique | length' "$index_file")
  local total_categories=$(jq '[.[] | .categories[]] | unique | length' "$index_file")
  local most_used_snippet=$(jq -r 'to_entries | max_by(.value.usage_frequency) | .key' "$index_file")
  local most_used_snippet_count=$(jq -r 'to_entries | max_by(.value.usage_frequency) | .value.usage_frequency' "$index_file")

  echo "KiloCode Memory Bank Statistics"
  echo "---------------------------------"
  echo "Total snippets: $total_snippets"
  echo "Total tags: $total_tags"
  echo "Total categories: $total_categories"
  echo "Most used snippet: '$most_used_snippet' (used $most_used_snippet_count times)"
}

# Main CLI function with comprehensive help and subcommand handling
kilocode() {
  local command="$1"
  shift

  # Display help if no command is provided
  if [[ -z "$command" ]]; then
    _kilocode_help
    return 0
  fi

  case "$command" in
    save)
      # If no arguments are provided, run in interactive mode
      if [[ $# -eq 0 ]]; then
        save_snippet_interactive
      else
        save_snippet "$@"
      fi
      ;;
    list)
      list_snippets
      ;;
    get)
      get_snippet "$@"
      ;;
    search)
      search_snippets "$@"
      ;;
    delete)
      delete_snippet "$@"
      ;;
    info)
      info_snippet "$@"
      ;;
    searchtag)
      search_by_tag "$@"
      ;;
    searchcat)
      search_by_category "$@"
      ;;
    searchcontent)
      search_by_content "$@"
      ;;
    clearcache)
      clear_metadata_cache
      ;;
    fuzzy)
      fuzzy_search_snippets "$@"
      ;;
    filter)
      search_by_tags_and_content "$@"
      ;;
    combo)
      combined_search "$@"
      ;;
    branch)
      _kilocode_git_branch "$@"
      ;;
    tag)
      _kilocode_git_tag "$@"
      ;;
    push)
      _kilocode_git_push
      ;;
    pull)
      _kilocode_git_pull
      ;;
    resolve)
      _kilocode_git_resolve_conflicts
      ;;
    config)
      _kilocode_config "$@"
      ;;
    stats)
      _kilocode_stats
      ;;
    help|--help|-h)
      _kilocode_help
      ;;
    *)
      echo "Error: Invalid command '$command'."
      echo "Use 'kilocode help' for a list of available commands."
      return 1
      ;;
  esac
}

# Initialize the system
init_kilocode_memory_bank

# Function for command completion
_kilocode_completions() {
  local -a commands
  commands=(
    'save:Save a snippet'
    'get:Retrieve a snippet'
    'list:List all snippets'
    'delete:Delete a snippet'
    'info:Show snippet metadata'
    'search:Search snippets'
    'searchtag:Search by tag'
    'searchcat:Search by category'
    'searchcontent:Search by content'
    'fuzzy:Fuzzy search'
    'filter:Filter by tags and search content'
    'combo:Combined tag and fuzzy search'
    'branch:Create a new branch'
    'tag:Create a new tag'
    'push:Push changes'
    'pull:Pull changes'
    'resolve:Resolve conflicts'
    'config:Manage configuration'
    'stats:Show statistics'
    'clearcache:Clear metadata cache'
    'help:Show help'
  )
  _describe 'command' commands

  case "$words" in
    get|delete|info)
      local snippets_dir=$(get_snippets_dir)
      local -a snippets
      snippets=($(cd "$snippets_dir" && find . -type f -not -name "*.json" -not -path "./.*/*" | sed 's|./||'))
      _describe 'snippet' snippets
      ;;
    config)
      local -a config_actions
      config_actions=('get:Get a configuration value' 'set:Set a configuration value' 'list:List all configuration values')
      _describe 'action' config_actions
      ;;
  esac
}

# Register completion function
compdef _kilocode_completions kilocode

# Create convenient aliases
alias ksave='kilocode save'
alias klist='kilocode list'
alias kget='kilocode get'
alias ksearch='kilocode search'
alias kdelete='kilocode delete'
alias kinfo='kilocode info'
alias ksearchtag='kilocode searchtag'
alias ksearchcat='kilocode searchcat'
alias ksearchcontent='kilocode searchcontent'
alias kclearcache='kilocode clearcache'
alias kfuzzy='kilocode fuzzy'
alias kfilter='kilocode filter'
alias kcombo='kilocode combo'
alias kbranch='kilocode branch'
alias ktag='kilocode tag'
alias kpush='kilocode push'
alias kpull='kilocode pull'
alias kresolve='kilocode resolve'
