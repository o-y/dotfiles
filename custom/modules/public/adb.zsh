# Master command function
function ad() {
  local subcmd="$1"

  if [[ -z $subcmd ]]; then  
    ad_help
    return
  fi

  # shift $subcmd
  shift

  case $subcmd in
    wifi)   ad_wifi "$@" ;;  
    text)   ad_text "$@" ;;
    textc)  ad_textc ;;      
    screenshot) ad_screenshot ;;
    help)   ad_help ;; 
    *)      _ad_error "Unknown subcommand: $subcmd" ;; 
  esac
}

# Sub-command functions
function ad_wifi() {
  local action="$1"
  if [[ $action == "off" ]]; then
    _ad_log "disabling wifi"
    adb shell svc wifi disable
  elif [[ $action == "on" ]]; then
    _ad_log "enabling wifi"
    adb shell svc wifi enable
  else
    _ad_error "invalid Wi-Fi action: $action"
  fi
}

function ad_text() {
  local text_to_send="$*"  
  
  text=$(printf '%s%%s' ${text_to_send})  # concatenate and replace spaces with %s
  text=${text%%%s}  # remove the trailing %s
  text=${text//\'/\\\'}  # escape single quotes
  text=${text//\"/\\\"}  # escape double quotes

  _ad_log "writing [$text] to device"
  adb shell input text "$text"
}

function ad_textc() {
  _ad_log "fetching clipboard"
  text=$(xclip -selection clipboard -o)
  ad_text "$text"
}

function ad_screenshot() {
  tmpfile="$(mktemp --suffix=".png")"

  _ad_log "taking screenshot and writing to $tmpfile"
  adb exec-out screencap -p > "$tmpfile"

  # open in chrome
  if type google-chrome &> /dev/null; then
    _ad_log "opening in chrome..."
    google-chrome "$tmpfile"
  elif [[ $(uname) == 'Linux' ]]; then
    _ad_log "opening using default image browser..."
    xdg-open "$tmpfile"
  elif [[ $(uname) == 'Darwin' ]]; then
    _ad_log "opening using default image browser..."
    open "$tmpfile"
  else
    _ad_error "couldn't find a program to open $tmpfile"
  fi
}

# Help Function
function ad_help() {
  echo "Usage: ad <subcommand> [options]"
  echo ""
  echo "Available subcommands:"
  echo "  help        Shows the help menu"
  echo "  wifi        Control Wi-Fi (on/off)"
  echo "  text        Emulate typing text (text)" 
  echo "  textc       Emulate typing text from the local clipboard"
  echo "  screenshot  Take a screenshot and copy to local clipboard"
}

# Error Handling
function _ad_error() {
  echo "[adutil ERROR] - $@" 1>&2  
}

function _ad_log() {
  echo "[adutil LOG] - $@" 1>&2  
}

#############################
#### COMPLETIONS
#############################

function _ad() {
  local curcontext="$curcontext" state line
  typeset -A opt_args

  # Separate 'words' of the current command line
  _arguments -C \
    '1: :->subcmds' \
    '*:: :->args'

  if [[ $state == subcmds ]]; then
    # Offer subcommand completions
    compadd wifi text textc screenshot help
  elif [[ $state == args ]]; then
    case $line[1] in
      wifi) 
        compadd on off 
        ;;
    esac
  fi
}

compdef _ad ad