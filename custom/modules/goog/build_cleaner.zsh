function bcd() {
    echo "[buildcleaner] running build_cleaner (add/remove) on target $1"
    __buildcleaner "$1" --tool_tag=javac
}

function bca() {
    echo "[buildcleaner] running build_cleaner (add) on target $1"
    __buildcleaner "$1" --tool_tag=javac --only-add
}

# compdef '_files' bcd
# compdef '_files' bca

function __buildcleaner() {
  args=("$@")

  local parameter=""
  local flags=()

  for arg in "${args[@]}"; do
    if [[ ${arg} == --* ]]; then
      flags+=("${arg}")
    else
      parameter="${arg}"
    fi
  done

  if [[ -z "$parameter" ]]; then
    echo "[buildcleaner] applying to current cl"
    build_cleaner "$flags"
  elif [[ -f "$parameter" ]]; then
    echo "[buildcleaner] applying to file: $parameter"
    build_cleaner "$parameter" "$flags"
  elif [[ "$parameter" == ///* || ! -f "$parameter" ]]; then
     echo "[buildcleaner] applying to target: $parameter"
     build_cleaner "$parameter" "$flags"
  fi
}
