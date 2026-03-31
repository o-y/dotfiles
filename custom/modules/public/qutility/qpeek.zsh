# ==========================================
# QPEEK: File Dispatcher
# ==========================================

# --- CONFIGURATION ---
typeset -gA QPEEK_HANDLERS=(
  "text"     "bat $EDITOR cat code"
  "markdown" "glow :text"
  "json"     "jless fx jq :text"
  "yaml"     "yq :text"
  "csv"      "vd tv column :text"
  "html"     "w3m lynx elinks :text"
  "log"      "lnav multitail less cat"
  "image"    "wezterm_imgcat kitty_icat chafa timg viu"
  "pdf"      "pdftotext"
  "binary"   "hexyl xxd hexdump"
  
  # Archive Management
  "archive"  "extract:_qpeek_handler_extract atool bsdtar tar unzip"

  # Execution Handlers (Run first, view second)
  "sh"       "bash:bash :text"
  "zsh"      "zsh:zsh :text"
  "python"   "python:python3 :text"
  "ts"       "bun:bun :text"
  "c"        "c:_qpeek_handler_run_c :text"
  "cpp"      "cpp:_qpeek_handler_run_cpp :text"
  "rust"     "rust:_qpeek_handler_run_rust :text"
  "go"       "go:_qpeek_handler_run_go :text"
)

typeset -gA QPEEK_MAP=(
  # Docs / Data / Media
  "txt conf ini env"                             "text"
  "md markdown"                                  "markdown"
  "json"                                         "json"
  "yml yaml"                                     "yaml"
  "log"                                          "log"
  "csv tsv"                                      "csv"
  "png jpg jpeg gif webp svg bmp"                "image"
  "pdf"                                          "pdf"
  "zip tar gz bz2 xz tgz 7z"                     "archive"
  "html htm"                                     "html"
  "bin exe dll so a o class pyc"                 "binary"

  # Executable Source Code
  "sh"                                           "sh"
  "zsh"                                          "zsh"
  "py"                                           "python"
  "ts"                                           "ts"
  "c"                                            "c"
  "cpp"                                          "cpp"
  "rs"                                           "rust"
  "go"                                           "go"
)


# --- ENGINE ---
typeset -gA _QPEEK_FLAT_MAP

# Flatten the map and setup suffix aliases automatically
for exts in ${(k)QPEEK_MAP}; do
  local target_handler="${QPEEK_MAP[$exts]}"
  for ext in ${(s: :)exts}; do
    _QPEEK_FLAT_MAP[$ext]="$target_handler"
    alias -s "$ext"="qpeek"
  done
done

# Recursively expand `:` references
_qpeek_expand() {
  local target="$1"
  local raw_str="${QPEEK_HANDLERS[$target]}"
  local words=(${(z)raw_str})
  local resolved=()

  for word in $words; do
    if [[ "$word" == :* ]]; then
      resolved+=($(_qpeek_expand "${word:1}"))
    else
      resolved+=("$word")
    fi
  done
  
  echo "${resolved[@]}"
}

# The main UI and execution wrapper
qpeek() {
  local file="$1"
  
  # Allow clearing cache manually
  if [[ "$file" == "--clear-cache" ]]; then
    local cache_file="${XDG_CACHE_HOME:-$HOME/.cache}/qpeek/history"
    [[ -f "$cache_file" ]] && rm -f "$cache_file"
    echo "Qpeek cache cleared."
    return 0
  fi

  [[ ! -f "$file" ]] && { echo "File not found: $file"; return 1; }

  local ext="${file:e}"
  local handler_name="${_QPEEK_FLAT_MAP[$ext]:-text}"
  
  local expanded_str=$(_qpeek_expand "$handler_name")
  local raw_options=( ${(z)expanded_str} )
  
  # --- CHECK AND SORT OPTIONS ---
  local available=()
  local unavailable=()

  for opt in "${raw_options[@]}"; do
    local cmd="${opt#*:}"
    local label="${opt%%:*}"
    
    # command -v checks for binaries, aliases, and functions
    if command -v "$cmd" >/dev/null 2>&1; then
      available+=("$opt")
    else
      unavailable+=("× ${label}:${cmd}")
    fi
  done

  # Rebuild options array with available items first
  local options=( "${available[@]}" "${unavailable[@]}" )
  local count=${#options[@]}
  local current=1

  # --- CACHE MANAGEMENT: LOAD ---
  local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/qpeek"
  [[ ! -d "$cache_dir" ]] && mkdir -p "$cache_dir"
  local cache_file="$cache_dir/history"
  local saved_opt=""

  if [[ -f "$cache_file" ]]; then
    # Grab the exact match for the extension
    saved_opt=$(grep "^${ext}=" "$cache_file" | tail -n 1 | cut -d'=' -f2-)
  fi

  # Set default if a cached option exists and is in the current options
  if [[ -n "$saved_opt" ]]; then
    for i in {1..$count}; do
      if [[ "${options[$i]}" == "$saved_opt" ]]; then
        current=$i
        break
      fi
    done
  fi

  # Pure Zsh array shuffle for colors 1 through 6
  local pool=(1 2 3 4 5 6)
  local shuffled_pool=()
  while (( ${#pool[@]} > 0 )); do
    local r=$(( RANDOM % ${#pool[@]} + 1 ))
    shuffled_pool+=(${pool[$r]})
    pool[$r]=()
    pool=("${(@)pool}") # Rebuild to drop empty indices
  done

  # Map a random color to each option
  local option_colors=()
  for i in {1..$count}; do
    local idx=$(( (i - 1) % ${#shuffled_pool[@]} + 1 ))
    option_colors[$i]=${shuffled_pool[$idx]}
  done

  local esc=$'\e'
  local reset="${esc}[0m"
  local bold="${esc}[1m"

  print -n "${esc}[?25l" # Hide cursor
  print "" 

  while true; do
    local line=""
    for i in {1..$count}; do
      local raw_option="${options[$i]}"
      local label="${raw_option%%:*}" # Extract everything before the colon
      
      local display_label=" ${label} "
      local c=${option_colors[$i]}
      
      if [[ $i -eq $current ]]; then
        # Active: Colored Background (1-6), Black Text (0), Bold
        line+="${esc}[48;5;${c}m${esc}[38;5;0m${bold}${display_label}${reset} "
      else
        # Inactive: Gray Background (236), Colored Text (1-6)
        line+="${esc}[48;5;236m${esc}[38;5;${c}m${display_label}${reset} "
      fi
    done
    
    print -r -- "$line"
    print "" 

    read -rs -k 1 key
    case "$key" in
      $'\e')
        read -rs -k 2 rest
        case "$rest" in
          '[D') (( current = current == 1 ? count : current - 1 )) ;; # Left
          '[C') (( current = current == count ? 1 : current + 1 )) ;; # Right
        esac
        ;;
      $'\n'|$'\r') # Enter
        break
        ;;
      'q') # Quit gracefully
        print -n "${esc}[?25h${esc}[3A\r${esc}[J" 
        return 0
        ;;
    esac

    print -n "${esc}[2A\r${esc}[J"
  done

  # Clear UI and restore cursor
  print -n "${esc}[?25h${esc}[3A\r${esc}[J"
  
  local raw_option="${options[$current]}"
  local cmd="${raw_option#*:}"

  # --- CACHE MANAGEMENT: SAVE ---
  if [[ "$saved_opt" != "$raw_option" ]]; then
    if [[ -f "$cache_file" ]]; then
      local tmp_file="${cache_file}.tmp"
      # Strip out any existing line for this extension
      grep -v "^${ext}=" "$cache_file" > "$tmp_file" 2>/dev/null || : > "$tmp_file"
      mv "$tmp_file" "$cache_file"
    fi
    # Append the new preference cleanly
    echo "${ext}=${raw_option}" >> "$cache_file"
  fi
  
  eval "$cmd \"\$file\""
}

# --- HANDLERS ---
_qpeek_handler_extract() {
  local file="$1"
  case "$file" in
    *.tar.bz2|*.tbz2) tar xvjf "$file" ;;
    *.tar.gz|*.tgz)   tar xvzf "$file" ;;
    *.tar.xz|*.txz)   tar xvJf "$file" ;;
    *.tar)            tar xvf "$file" ;;
    *.zip)            unzip "$file" ;;
    *.gz)             gunzip -k "$file" ;;
    *.bz2)            bunzip2 -k "$file" ;;
    *.xz)             unxz -k "$file" ;;
    *.7z)             7z x "$file" ;;
    *)                echo "Unsupported archive format: $file" ;;
  esac
}

_qpeek_handler_run_c() {
  local file="$1"
  local out="${file:r}.out"
  cc "$file" -o "$out" && "./$out"
}

_qpeek_handler_run_cpp() {
  local file="$1"
  local out="${file:r}.out"
  c++ "$file" -o "$out" && "./$out"
}

_qpeek_handler_run_rust() {
  local file="$1"
  local out="${file:r}"
  rustc "$file" -o "$out" && "./$out"
}

_qpeek_handler_run_go() {
  go run "$1"
}