export ZSH_EVALCACHE_DIR=${ZSH_EVALCACHE_DIR:-"$HOME/.cache/.zsh-evalcache"}

# ==============================================================================
# _eval_cache
# ==============================================================================
# Caches the output of a binary initialisation command and hashes this.
#
# Usage:
#   _eval_cache [NAME=VALUE]... COMMAND [ARG]...
#
# Environment Variables:
#   ZSH_EVALCACHE_DIR     - Directory to store cached scripts (default: ~/.cache/.zsh-evalcache)
#   ZSH_EVALCACHE_DISABLE - Set to "true" to temporarily bypass cache execution
# ==============================================================================
_eval_cache() {
  local cmdHash="nohash" data="$*" name

  for name in $@; do
    if [ "${name}" = "${name#[A-Za-z_][A-Za-z0-9_]*=}" ]; then
      break
    fi
  done

  if typeset -f "${name}" > /dev/null 2>&1; then
    data=${data}$(typeset -f "${name}")
  fi

  if builtin command -v md5 > /dev/null 2>&1; then
    cmdHash=$(echo -n "${data}" | md5)
  elif builtin command -v md5sum > /dev/null 2>&1; then
    cmdHash=$(echo -n "${data}" | md5sum | cut -d' ' -f1)
  fi

  local cacheFile="$ZSH_EVALCACHE_DIR/init-${name##*/}-${cmdHash}.sh"

  if [ "$ZSH_EVALCACHE_DISABLE" = "true" ]; then
    eval ${(q)@} 2>/dev/null
    return $?
  elif [ -s "$cacheFile" ]; then
    source "$cacheFile" 2>/dev/null
    return $?
  else
    if type "${name}" > /dev/null 2>&1; then
      mkdir -p "$ZSH_EVALCACHE_DIR"
      if eval ${(q)@} > "$cacheFile" 2>/dev/null; then
        zcompile "$cacheFile" 2>/dev/null
        source "$cacheFile" 2>/dev/null
        return $?
      else
        rm -f "$cacheFile"
        return 1
      fi
    fi
    return 1
  fi
}

# ==============================================================================
# _eval_binary
# ==============================================================================
# Checks a list of candidate paths for an executable binary, and if found
# executes the binary.
#
# Usage:
#   _eval_binary PATH_CANDIDATE... -- INIT_ARG...
#
# Example:
#   _eval_binary "$commands[foo]" "~/.cargo/bin/foo" -- init zsh
# ==============================================================================
_eval_binary() {
  local candidates=()
  local args=()
  local parsing_paths=1
  local arg bin

  for arg in "$@"; do
    if [[ "$arg" == "--" && $parsing_paths -eq 1 ]]; then
      parsing_paths=0
      continue
    fi

    if (( parsing_paths )); then
      if [[ -n "$arg" ]]; then 
        candidates+=("${~arg}")
      fi
    else
      args+=("$arg")
    fi
  done

  for bin in "${candidates[@]}"; do
    if [[ -x $bin ]]; then
      if (( $+functions[_eval_cache] || $+commands[_eval_cache] )); then
        _eval_cache "$bin" "${args[@]}" 2>/dev/null
        return $? 
      else
        eval "$("$bin" "${args[@]}" 2>/dev/null)" 2>/dev/null
        return $?
      fi
    fi
  done
  
  return 1
}