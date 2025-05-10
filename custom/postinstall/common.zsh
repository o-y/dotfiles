echo "[~] postinstall :: starting common-post-install subroutine" 

######## Platform Install Scripts ########
PATH_TO_SCRIPT=$(realpath "$0")
SCRIPT_DIR=$(dirname "$PATH_TO_SCRIPT")

source_helper() {
  file="$1"
  file_uname="$2"

  if [[ $(uname) == $file_uname || $file_uname == "common" ]]; then
    source "$file"
  fi
}

for file in "$SCRIPT_DIR/modules"/*; do
  filename=$(basename "$file")
  if [[ $filename == *.darwin.zsh ]]; then
    source_helper "$file" "Darwin"
  elif [[ $filename == *.linux.zsh ]]; then
    source_helper "$file" "Linux"
  elif [[ $filename == *.zsh ]]; then
    source_helper "$file" "common"
  fi
done