function find_blaze_invocation() {
  pattern="^/google/src/cloud/(.+)/(.+)/google3(/.*)?$"

  if [[ $PWD =~ $pattern ]]; then
    changelist_path="/google/src/cloud/${match[1]}/${match[2]}/google3/blaze-out/build-changelist.txt"

    if [[ -f $changelist_path ]]; then
      sponge_id=$(grep BUILD_ID "${changelist_path}" | cut -d' ' -f 2)
      echo $sponge_id
      return 0
    else
      return 1  # build-changelist.txt not found in expected location
    fi
  else
    return 2  # not in a supported directory structure
  fi
}

function wrapped_blaze() {
  local exit_code
  local target

  target="${!#}"
  /usr/bin/blaze "$@"
  exit_code=$?

  # i should clean this up
  if type dunstify &> /dev/null; then
    if [ $exit_code -eq 0 ]; then
      dunstify --appname="Blaze Build" \
        "Blaze Success!" \
        "Action:browser,http://sponge2/$(find_blaze_invocation)"
    else
      dunstify --appname="Blaze Build" \
        "Blaze Failure!" \
        "Action:browser,http://sponge2/$(find_blaze_invocation)"
    fi
  fi

  if type google-chat-alert &> /dev/null; then
    if [ $exit_code -eq 0 ]; then
      google-chat-alert "Blaze Build Success - http://sponge2/$(find_blaze_invocation)"
    else
      google-chat-alert "Blaze Build Failure - http://sponge2/$(find_blaze_invocation)"
    fi
  fi

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