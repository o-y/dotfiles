# --- Helpers ---

local device_uname=$(uname)

# Returns success if the file is encrypted via git-crypt
_compiler_is_encrypted() {
  [[ -r "$1" && "$(head -n 1 "$1" 2>/dev/null)" == *GITCRYPT* ]]
}

_compiler_should_skip_platform() {
  local file="$1"
  case "$file" in
    *.darwin.zsh) [[ "$device_uname" != "Darwin" ]] && return 0 ;;
    *.linux.zsh)  [[ "$device_uname" != "Linux" ]]  && return 0 ;;
  esac
  return 1
}

_compiler_should_defer() {
  [[ "$2" == "sync" || "$1" == *.nodefer.* ]] && return 1
  return 0
}

_compiler_process_file() {
  local file="$1" mode="$2"

  if _compiler_is_encrypted "$file" || _compiler_should_skip_platform "$file"; then
    _compiler_is_encrypted "$file" && skipped_files+=("$file")
    return
  fi

  local is_post=0
  [[ "$file" == *.post.* ]] && is_post=1

  if _compiler_should_defer "$file" "$mode"; then
    if (( is_post )); then
      defer_post_files+=("$file")
    else
      defer_files+=("$file")
    fi
  else
    if (( is_post )); then
      sync_post_files+=("$file")
    else
      sync_files+=("$file")
    fi
  fi
}

# Emits a file's content with a header comment, optionally indented.
# Usage: _compiler_emit_file <file> [indent]
_compiler_emit_file() {
  local file="$1" indent="${2:-}"
  if [[ -r "$file" ]]; then
    echo "${indent}### > $file"
    if [[ -n "$indent" ]]; then
      sed "s/^/${indent}/" "$file"
    else
      cat "$file"
    fi
    echo ""
  else
    echo "${indent}source \"$file\""
  fi
}

# --- Main ---

generate_static_loader() {
  local output_file="$STATIC_LOADER"
  local tmp_zsh="${output_file}.tmp"
  local tmp_zwc="${output_file}.zwc.tmp"
  local sync_files=() sync_post_files=() defer_files=() defer_post_files=() skipped_files=()

  for file in "$MODULES_DIR"/dependencies/**/*.zsh(N); do
    _compiler_process_file "$file" "sync"
  done
  for file in "$MODULES_DIR"/{public,private,goog}/**/*.zsh(N); do
    _compiler_process_file "$file" "defer"
  done

  {
    echo "### Generated at: $(date)"
    cat "${MODULES_DIR:h}/hooks.zsh"
    echo ""
    echo "zsh_pre_init"
    echo ""

    for f in "${sync_files[@]}"; do
      _compiler_emit_file "$f"
    done

    # Synchronous post files are emitted at the end of the sync block
    for f in "${sync_post_files[@]}"; do
      _compiler_emit_file "$f"
    done

    echo "zsh_post_init"
    echo ""

    if (( ${#defer_files} || ${#defer_post_files} )); then
      echo "_zsh_deferred_load() {"
      for f in "${defer_files[@]}"; do
        _compiler_emit_file "$f" "  "
      done

      # Deferred post files are emitted at the absolute end of the deferred block
      for f in "${defer_post_files[@]}"; do
        _compiler_emit_file "$f" "  "
      done
      echo "}"
      echo "zsh-defer _zsh_deferred_load"
    fi
  } > "$tmp_zsh"

  if zcompile "$tmp_zsh"; then
    mv -f "${tmp_zsh}.zwc" "$tmp_zwc"
    mv -f "$tmp_zsh" "$output_file"
    [[ -f "$tmp_zwc" ]] && mv -f "$tmp_zwc" "${output_file}.zwc"
  else
    echo "Error: zcompile failed for $tmp_zsh" >&2
    return 1
  fi
}