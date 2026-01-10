# --- Internal Helper Functions ---

# Returns success if the file is encrypted via git-crypt
_compiler_is_encrypted() {
  [[ -r "$1" && "$(head -n 1 "$1" 2>/dev/null)" == *GITCRYPT* ]]
}

# Returns success if the file belongs to an OS other than the current one
_compiler_should_skip_platform() {
  local file="$1"
  case "$file" in
    *.darwin.zsh) [[ "$UNAME" != "Darwin" ]] && return 0 ;;
    *.linux.zsh)  [[ "$UNAME" != "Linux" ]]  && return 0 ;;
  esac
  return 1
}

# Determines if a file should be sourced deferred or immediately
_compiler_should_defer() {
  local file="$1" mode="$2"

  # Synchronous mode or explicit '.nodefer.' tag prevents deferral
  [[ "$mode" == "sync" || "$file" == *.nodefer.* ]] && return 1

  return 0
}

# Returns the correct source command string for a given file
_compiler_get_source_cmd() {
  local file="$1" mode="$2"

  if _compiler_should_defer "$file" "$mode"; then
    printf 'zsh-defer source "%s"' "$file"
  else
    printf 'source "%s"' "$file"
  fi
}

# High-level processor: filters and collects the source command into the appropriate array
_compiler_process_file() {
  local file="$1" mode="$2"

  if _compiler_is_encrypted "$file"; then
    skipped_files+=("$file")
    return
  fi

  if _compiler_should_skip_platform "$file"; then
    return
  fi

  local cmd=$(_compiler_get_source_cmd "$file" "$mode")
  if [[ "$cmd" == zsh-defer* ]]; then
    defer_lines+=("$cmd")
  else
    sync_lines+=("$cmd")
  fi
}

# Emits the shell logic for the git-crypt warning system
_compiler_emit_warning_logic() {
  cat <<'EOF'
if [[ ! -e "$HOME/silence-git-crypt-warnings" && ! -e "$HOME/.silence-git-crypt-warnings" ]]; then
  echo "[!] WARNING: The following encrypted files were skipped:"
  echo "[!] --- ↓"
  for file in "${skipped_files[@]}"; do
    echo "[!]     $file"
  done
  echo "[!] --- ↑"
  echo "[!] Run '$ git-crypt unlock' to decrypt them."
  echo "[!] To silence these warnings, execute '$ touch ~/.silence-git-crypt-warnings'"
fi
EOF
}

# --- Main Generator Logic ---

# Generates the static loader script
generate_static_loader() {
  local output_file="$STATIC_LOADER"
  local tmp_file="${output_file}.tmp"
  local sync_lines=()
  local defer_lines=()
  local skipped_files=()

  # 1. Collect all module commands
  for file in "$MODULES_DIR"/dependencies/**/*.zsh(N); do
    _compiler_process_file "$file" "sync"
  done

  for file in "$MODULES_DIR"/{public,private,goog}/**/*.zsh(N); do
    _compiler_process_file "$file" "defer"
  done

    # 2. Emit the script
    {
        echo "################################################################"
        echo "### Generated static zsh loader - do not edit manually"
        echo "### Generated at: $(date)"
        echo "### ~ https://github.com/o-y/dotfiles"
        echo "################################################################"
        echo ""

        # Inline Hooks
        echo "### ------------------------------------- ###"
        echo "### ----------- INLINED HOOKS ----------- ###"
        echo "### ------------------------------------- ###"
        cat "${MODULES_DIR:h}/hooks.zsh"
        echo ""
        echo "zsh_pre_init"
        echo ""

        # Synchronous block (critical Dependencies + .nodefer modules)
        if (( ${#sync_lines} > 0 )); then
            echo "### --- SYNCHRONOUS MODULES (INLINED) --- ###"
            for line in "${sync_lines[@]}"; do
                # extract file path from 'source "/path/to/file"'
                local file_to_inline="${${line%\"}#*\"}"
                if [[ -r "$file_to_inline" ]]; then
                    echo "### ------------------------------------- ###"
                    echo "### > $file_to_inline"
                    echo "### ------------------------------------- ###"
                    echo ""
                    cat "$file_to_inline"
                    echo ""
                else
                    echo "$line"
                fi
            done
            printf '\n'
        fi

        echo "zsh_post_init"
        echo ""

        # Deferred block (Standard Modules)
        if (( ${#defer_lines} > 0 )); then
            echo "### --- DEFERRED MODULES --- ###"
            for line in "${defer_lines[@]}"; do
                printf '%s\n' "$line"
            done
            printf '\n'
        fi

        # Handle Encrypted/Skipped Files
        if (( ${#skipped_files} > 0 )); then
            echo "################################################################"
            echo "### SKIPPED ENCRYPTED FILES"
            echo "################################################################"
            echo ""
            echo "skipped_files=("
            for f in "${skipped_files[@]}"; do
                printf '  "%s"\n' "$f"
            done
            echo ")"
            
            _compiler_emit_warning_logic
        fi
    } > "$tmp_file"

    mv "$tmp_file" "$output_file"
    zcompile "$output_file"
}
