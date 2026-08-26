# ==========================================
# QPEEK: File Dispatcher
# ==========================================

# --- CONFIGURATION ---
# time in seconds before auto-executing the last used handler (0 to disable)
typeset -g QPEEK_AUTO_EXEC_TIMEOUT=1.5

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
  "zip tar gz bz2 xz tgz 7z rar zst deb Z"       "archive"
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


# --- ENGINE CORE ---
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

# --- UI MODULE ---
_qpeek_prompt_selection() {
  local ret_var="$1"
  local saved_opt="$2"
  shift 2
  local options=("$@")
  local count=${#options[@]}
  local current=1

  # auto Execution Setup (parse float timeout to 0.1s ticks)
  local auto_execute=0
  local float_ticks=$(( QPEEK_AUTO_EXEC_TIMEOUT * 10 ))
  local max_ticks=${float_ticks%.*} # strip decimal if present
  local ticks=$max_ticks

  # find saved option in current array to set default & trigger auto-exec
  if [[ -n "$saved_opt" && $max_ticks -gt 0 ]]; then
    for i in {1..$count}; do
      if [[ "${options[$i]}" == "$saved_opt" ]]; then
        current=$i
        auto_execute=1
        break
      fi
    done
  fi

  # generate random colors for options
  local pool=(1 2 3 4 5 6)
  local shuffled_pool=()
  while (( ${#pool[@]} > 0 )); do
    local r=$(( RANDOM % ${#pool[@]} + 1 ))
    shuffled_pool+=(${pool[$r]})
    pool[$r]=()
    pool=("${(@)pool}")
  done

  local option_colors=()
  for i in {1..$count}; do
    local idx=$(( (i - 1) % ${#shuffled_pool[@]} + 1 ))
    option_colors[$i]=${shuffled_pool[$idx]}
  done

  local esc=$'\e'
  local reset="${esc}[0m"
  local bold="${esc}[1m"

  # trap: Ctrl+C to restore cursor and clean up lines
  trap 'print -n "\e[?25h\e[4A\r\e[J"; return 130' INT

  print -n "${esc}[?25l" # Hide cursor
  print "" 

  while true; do
    local line=""
    for i in {1..$count}; do
      local raw_option="${options[$i]}"
      local label="${raw_option%%:*}"
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
    
    local prompt_line=""
    if (( auto_execute == 1 )); then
      prompt_line="${esc}[38;5;245mAuto-executing in $(( ticks / 10 )).$(( ticks % 10 ))s...${reset}"
    fi

    print -r -- "$line"
    print "" 
    print -r -- "$prompt_line"

    local key="" rest=""
    if (( auto_execute == 1 )); then
      # non-blocking read with 0.1s timeout
      if read -rs -t 0.1 -k 1 key; then
        auto_execute=0 # user intervened, cancel auto-execute
      else
        (( ticks-- ))
        if (( ticks <= 0 )); then
          break # timer reached 0, execute
        fi
        print -n "${esc}[3A\r${esc}[J"
        continue
      fi
    else
      # standard blocking read
      read -rs -k 1 key
    fi

    case "$key" in
      $'\e')
        read -rs -t 0.1 -k 2 rest
        case "$rest" in
          '[D') (( current = current == 1 ? count : current - 1 )) ;; # Left
          '[C') (( current = current == count ? 1 : current + 1 )) ;; # Right
        esac
        ;;
      $'\n'|$'\r') # enter
        break
        ;;
      'q') # exit
        print -n "${esc}[?25h${esc}[4A\r${esc}[J" 
        trap - INT
        return 1
        ;;
    esac

    # clear UI for the next loop iteration (3 lines: options, gap, timer/empty)
    print -n "${esc}[3A\r${esc}[J"
  done

  # clear UI completely, restore cursor, and pass back selection
  print -n "${esc}[?25h${esc}[4A\r${esc}[J"
  trap - INT
  
  eval "$ret_var=\${options[\$current]}"
  return 0
}


# --- MAIN DISPATCHER ---
qpeek() {
  local file="$1"
  shift
  local args=("$@")
  
  # allow clearing cache manually
  if [[ "$file" == "--clear-cache" ]]; then
    local cache_file="${XDG_CACHE_HOME:-$HOME/.cache}/qpeek/history"
    [[ -f "$cache_file" ]] && rm -f "$cache_file"
    echo "[qpeek] cache cleared."
    return 0
  fi

  [[ ! -f "$file" ]] && { echo "[qpeek] file not found: $file"; return 1; }

  local ext="${file:e}"
  local handler_name="${_QPEEK_FLAT_MAP[$ext]:-text}"
  
  local expanded_str=$(_qpeek_expand "$handler_name")
  local raw_options=( ${(z)expanded_str} )
  
  # --- CHECK AVAILABLE COMMANDS ---
  local available=()
  local unavailable=()

  for opt in "${raw_options[@]}"; do
    local cmd="${opt#*:}"
    local label="${opt%%:*}"
    
    if command -v "$cmd" >/dev/null 2>&1; then
      available+=("$opt")
    else
      unavailable+=("× ${label}:${cmd}")
    fi
  done

  local options=( "${available[@]}" "${unavailable[@]}" )

  # --- CACHE MANAGEMENT: LOAD ---
  local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/qpeek"
  [[ ! -d "$cache_dir" ]] && mkdir -p "$cache_dir"
  local cache_file="$cache_dir/history"
  local saved_opt=""

  if [[ -f "$cache_file" ]]; then
    saved_opt=$(grep "^${ext}=" "$cache_file" | tail -n 1 | cut -d'=' -f2-)
  fi

  # --- PROMPT USER ---
  local selected_option=""
  if ! _qpeek_prompt_selection selected_option "$saved_opt" "${options[@]}"; then
    return 0 # User aborted via 'q' or Ctrl+C
  fi

  local cmd="${selected_option#*:}"

  # --- CACHE MANAGEMENT: SAVE ---
  if [[ "$saved_opt" != "$selected_option" ]]; then
    if [[ -f "$cache_file" ]]; then
      local tmp_file="${cache_file}.tmp"
      grep -v "^${ext}=" "$cache_file" > "$tmp_file" 2>/dev/null || : > "$tmp_file"
      mv "$tmp_file" "$cache_file"
    fi
    echo "${ext}=${selected_option}" >> "$cache_file"
  fi
  
  # Evaluate securely while preserving spaces in arguments
  eval "$cmd ${(q)file} ${(q)args[@]}"
}

# --- HANDLERS ---
_qpeek_handler_extract() {
  local file="$1"
  shift
  
  local mime
  mime=$(file --brief --mime-type -- "$file")

  case "$mime" in
    application/zip)
      unzip "$file" ;;
    application/x-7z-compressed)
      7z x "$file" ;;
    application/x-rar|application/vnd.rar)
      unrar x "$file" ;;
    application/x-tar)
      tar xf "$file" ;;
    application/gzip)
      tar xzf "$file" 2>/dev/null || gunzip -k "$file" ;;
    application/x-bzip2)
      tar xjf "$file" 2>/dev/null || bunzip2 -k "$file" ;;
    application/x-xz)
      tar xJf "$file" 2>/dev/null || unxz -k "$file" ;;
    application/zstd)
      tar --zstd -xf "$file" 2>/dev/null || unzstd "$file" ;;
    application/x-compress)
      uncompress "$file" ;;
    application/vnd.debian.binary-package)
      ar x "$file" ;;
    *)
      # Fallback to extension matching if MIME type is ambiguous
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
        *)                echo "[qpeek] archive extractor - unsupported archive format/MIME type: $mime for $file" ;;
      esac
      ;;
  esac
}

_qpeek_handler_run_c() {
  local file="$1"
  shift
  local tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/qpeek_c_XXXXXX")
  local out="$tmp_dir/${file:t:r}.out"
  cc "$file" -o "$out" && "$out" "$@"
  rm -rf "$tmp_dir"
}

_qpeek_handler_run_cpp() {
  local file="$1"
  shift
  local tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/qpeek_cpp_XXXXXX")
  local out="$tmp_dir/${file:t:r}.out"
  c++ "$file" -o "$out" && "$out" "$@"
  rm -rf "$tmp_dir"
}

_qpeek_handler_run_rust() {
  local file="$1"
  shift
  local tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/qpeek_rs_XXXXXX")
  local out="$tmp_dir/${file:t:r}"
  rustc "$file" -o "$out" && "$out" "$@"
  rm -rf "$tmp_dir"
}

_qpeek_handler_run_go() {
  go run "$@"
}

# --- ALIAS ---
alias q=qpeek