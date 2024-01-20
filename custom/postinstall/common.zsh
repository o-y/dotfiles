echo "[~] starting common-post-install subroutine" 

################ Sourcerer ###############
sourcerer_directory="$HOME/dotfiles/custom/static/binaries/sourcerer.zsh"
if [ -e $sourcerer_directory ]; then
    source $sourcerer_directory
else
    echo "[!] warning - sourcerer does not exist at $sourcerer_directory"
fi

######## Platform Install Scripts ########
PATH_TO_SCRIPT=$(realpath -s "$0")
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

################ Check Encryption ###############
echo "--------------------------------------------------------------------|"
echo "[!] warning - depending on user config, files may be encrypted      |"
echo "[!]           these can be unlocked using '$ git-crypt unlock, or   |"
echo "[!]           their status can be queried with $ git-crypt status   |"
echo "--------------------------------------------------------------------|"
read -q "answer?run '$ git-crypt unlock' [Y/n] "
echo ""
if [[ $answer == "y" || $answer == "Y" || $answer == "" ]]; then
    git-crypt unlock
fi