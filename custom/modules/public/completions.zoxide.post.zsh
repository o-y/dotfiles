(( $+commands[zoxide] )) || return 0

__zoxide_max_width=42

_zoxide_collapse_path() {
  local full="$1"

  # Replace $HOME prefix with a literal ~ (string comparison, not glob)
  local short="$full"
  if [[ "$full" == "$HOME/"* ]]; then
    short="~/${full#"$HOME/"}"
  elif [[ "$full" == "$HOME" ]]; then
    short="~"
  fi

  # Short circuit if the path is less than __zoxide_max_width.
  (( ${#short} <= __zoxide_max_width )) && { print -- "$short"; return }

  # Determine prefix and the slash-separated components to collapse
  local prefix rest
  if [[ "$short" == "~/"* ]]; then
    prefix="~"
    rest="${short#"~/"}"
  else
    prefix=""
    rest="${short#"/"}"
  fi

  local -a parts=( "${(@s:/:)rest}" )
  local n=$#parts

  # Not deep enough to be worth collapsing
  (( n <= 3 )) && { print -- "$short"; return }

  # ~/first/second/…/last  or  /first/second/…/last
  if [[ -n "$prefix" ]]; then
    print -- "${prefix}/${parts[1]}/${parts[2]}/…/${parts[$n]}"
  else
    print -- "/${parts[1]}/${parts[2]}/…/${parts[$n]}"
  fi
}

_zoxide_fuzzy_match() {
  local target="${1:l}" query="${2:l}"
  local i pos
  for (( i = 1; i <= $#query; i++ )); do
    pos="${target[(i)${query[i]}]}"
    (( pos == 0 )) && return 1
    target="${target[$((pos + 1)),-1]}"
  done
  return 0
}

_zoxide_autocomplete() {
  local query="${words[2]}"
  local limit=20

  local -a raw
  raw=( ${(f)"$(zoxide query -ls 2>/dev/null)"} )
  (( $#raw )) || return

  local -a labels insertions
  local count=0 entry dirpath

  for entry in "${raw[@]}"; do
    dirpath="${entry#*( )}"
    dirpath="/${dirpath#*/}"

    [[ -d "$dirpath" ]] || continue

    if [[ -n "$query" ]]; then
      _zoxide_fuzzy_match "$dirpath" "$query" || continue
    fi

    labels+=( "$(_zoxide_collapse_path "$dirpath")" )
    insertions+=( "${dirpath%/}/" )

    (( ++count >= limit )) && break
  done

  (( $#insertions )) || return

  # -V → unsorted group: preserves zoxide's frecency order (highest score first)
  #      without -V, zsh sorts alphabetically and buries the best match
  # -U → bypass zsh's prefix filter as we do our own fuzzy filtering
  # -Q → don't re-quote inserted values
  local expl
  _description -V zoxide-dirs expl 'zoxide'
  compadd "$expl[@]" -U -Q -d labels -- "${insertions[@]}"
}

# Wrap _cd to append our zoxide group, but preserve the original
# zoxide __zoxide_z_complete if it exists (used by zi / ctrl+z)
_zoxide_cd_with_zoxide() {
  _cd "$@"
  _zoxide_autocomplete
}

# Only override the cd completer; leave __zoxide_z_complete (zi) untouched
compdef _zoxide_cd_with_zoxide cd

# --- Debug helper ------------------------------------------------------
_zoxide_debug() {
  local query="${1:-}"
  echo "=== zoxide raw output (first 5 lines) ==="
  zoxide query -ls 2>&1 | head -5
  echo ""
  echo "=== parsed paths + labels ==="
  local -a raw
  raw=( ${(f)"$(zoxide query -ls 2>/dev/null)"} )
  local count=0 entry dirpath label
  for entry in "${raw[@]}"; do
    dirpath="${entry#*( )}"
    dirpath="/${dirpath#*/}"
    [[ -d "$dirpath" ]] || { echo "  (stale) $dirpath"; continue }
    if [[ -n "$query" ]]; then
      _zoxide_fuzzy_match "$dirpath" "$query" || continue
    fi
    label="$(_zoxide_collapse_path "$dirpath")"
    printf "  %-44s  →  %s\n" "$label" "$dirpath"
    (( ++count >= 10 )) && break
  done
}