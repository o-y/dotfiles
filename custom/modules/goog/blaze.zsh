function _find_blaze_invocation() {
  pattern="^/google/src/cloud/(.+)/(.+)/google3(/.*)?$"

  if [[ $PWD =~ $pattern ]]; then
    changelist_path="/google/src/cloud/${match[1]}/${match[2]}/google3/blaze-out/build-changelist.txt"

    if [[ -f $changelist_path ]]; then
      sponge_id=$(grep BUILD_ID "${changelist_path}" | cut -d' ' -f 2)
      echo $sponge_id
    fi
  fi
}

_blaze_notify_dunst() {
  (( ! $+commands[dunstify] )) && return 0

  local title="$1"
  local url="$2"
  local -a dunst_args

  dunst_args=("--appname=Blaze Build" "$title")

  if [[ -n "$url" ]]; then
    dunst_args+=("Action:browser,${url}")
  fi

  dunstify "${dunst_args[@]}"
}

_blaze_notify_google_chat() {
  (( ! $+commands[google-chat-alert] )) && return 0

  local title="$1"
  local url="$2"
  local message="$title"

  if [[ -n "$url" ]]; then
    message+=" - ${url}"
  fi

  google-chat-alert "$message"
}

_blaze_execution_hooks() {
  local -i exit_code="$1"
  local status_title
  local sponge_url
  local invocation_id

  if (( exit_code == 0 )); then
    status_title="Blaze Success!"
  else
    status_title="Blaze Failure!"
  fi

  invocation_id="$(_find_blaze_invocation)"
  if [[ -n "$invocation_id" ]]; then
    sponge_url="http://sponge2/${invocation_id}"
  fi

  _blaze_notify_dunst "$status_title" "$sponge_url"
  _blaze_notify_google_chat "$status_title" "$sponge_url"
}

function wrapped_blaze() {
  command /usr/bin/blaze "$@"
  local -i exit_code=$?

  _blaze_execution_hooks $exit_code

  return $exit_code
}

#### Blaze alias
alias blaze=wrapped_blaze
alias blaze2='blaze --output_base=/tmp/blaze-out-2'
alias blaze3='blaze --output_base=/tmp/blaze-out-3'
alias blaze4='blaze --output_base=/tmp/blaze-out-4'
alias blaze5='blaze --output_base=/tmp/blaze-out-5'
alias blaze6='blaze --output_base=/tmp/blaze-out-6'
alias blaze7='blaze --output_base=/tmp/blaze-out-7'
alias blaze8='blaze --output_base=/tmp/blaze-out-8'
alias blaze9='blaze --output_base=/tmp/blaze-out-9'
alias blaze10='blaze --output_base=/tmp/blaze-out-10'
alias blaze11='blaze --output_base=/tmp/blaze-out-11'
alias blaze12='blaze --output_base=/tmp/blaze-out-12'
alias blaze13='blaze --output_base=/tmp/blaze-out-13'
alias blaze14='blaze --output_base=/tmp/blaze-out-14'
alias blaze15='blaze --output_base=/tmp/blaze-out-15'
alias blaze16='blaze --output_base=/tmp/blaze-out-16'

#### Throw away blaze
blazed() {
  local random_number=$(( RANDOM % 1000 ))
  local output_base="/tmp/blaze-out-blazed-${random_number}"
  local blaze_command="blaze --output_base=${output_base} $@"

  local YELLOW='\033[1;33m'
  local NC='\033[0m' 
  echo -e "${YELLOW}INFO:${NC} Running using blazed with output_base: ${output_base}"
  eval "${blaze_command}"
  echo -e "${YELLOW}INFO:${NC} To rerun this command with the same cache use:"
  echo "  ${blaze_command}"
}