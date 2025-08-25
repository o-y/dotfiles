echo "[~] postinstall :: starting common-post-install subroutine" 

######## Hooks ########

pre_source_hook() {
  echo "[~] postinstall :: hook - running pre-source hook"
  echo "[~] postinstall :: hook - locking zshrc and zshenv files"

  [ -f "$HOME/.zshrc" ]  && chmod a-w ~/.zshrc
  [ -f "$HOME/.zshenv" ] && chmod a-w ~/.zshenv
}

post_source_hook() {
  echo "[~] postinstall :: hook - running post-source hook"
  echo "[~] postinstall :: hook - unlocking zshrc and zshenv files"

  [ -f "$HOME/.zshrc" ]  && chmod u+w ~/.zshrc
  [ -f "$HOME/.zshenv" ] && chmod u+w ~/.zshenv
}

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

pre_source_hook
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
post_source_hook