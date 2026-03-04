# --- Internal Helper Functions ---

_compiler_is_encrypted() {
  [[ -r "$1" && "$(head -n 1 "$1" 2>/dev/null)" == *GITCRYPT* ]]
}

_compiler_should_skip_platform() {
  local uname="$(uname -s)"
  case "$1" in
    *.darwin.zsh) [[ "$uname" != "Darwin" ]] && return 0 ;;
    *.linux.zsh)  [[ "$uname" != "Linux" ]]  && return 0 ;;
  esac
  return 1
}

_compiler_should_defer() {
  [[ "$2" == "sync" || "$1" == *.nodefer.* ]] && return 1
  return 0
}

_compiler_get_source_cmd() {
  if _compiler_should_defer "$1" "$2"; then
    # this used to use zsh-defer as well, but this branch is left
    # so the option is easy to reintroduce.
    printf 'source "%s"' "$1"
  else
    printf 'source "%s"' "$1"
  fi
}

_compiler_process_file() {
  local file="$1" mode="$2"
  
  if _compiler_is_encrypted "$file" || _compiler_should_skip_platform "$file"; then
    if _compiler_is_encrypted "$file"; then skipped_files+=("$file"); fi
    return
  fi
  
  local cmd=$(_compiler_get_source_cmd "$file" "$mode")
  
  if _compiler_should_defer "$file" "$mode"; then
    defer_lines+=("$cmd")
  else
    sync_lines+=("$cmd")
  fi
}

# --- Main Generator Logic ---

generate_static_loader() {
  local output_file="$STATIC_LOADER"
  local tmp_zsh="${output_file}.tmp"
  local tmp_zwc="${output_file}.zwc.tmp"
  local sync_lines=() defer_lines=() skipped_files=()

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

    if (( ${#sync_lines} )); then
      for line in "${sync_lines[@]}"; do
        local f="${${line%\"}#*\"}"
        if [[ -r "$f" ]]; then
          echo "### > $f"
          cat "$f"
          echo ""
        else
          echo "$line"
        fi
      done
    fi

    echo "zsh_post_init"
    echo ""

    if (( ${#defer_lines} )); then
      echo "_zsh_deferred_load() {"
      for line in "${defer_lines[@]}"; do
        echo "  zsh-defer $line"
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
