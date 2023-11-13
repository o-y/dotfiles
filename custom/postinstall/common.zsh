echo "[~] starting common-post-install subroutine" 

################ Sourcerer ###############
sourcerer_directory="$HOME/dotfiles/custom/static/binaries/sourcerer.zsh"
if [ -e $sourcerer_directory ]; then
    source $sourcerer_directory
else
    echo "[!] warning - sourcerer does not exist at $sourcerer_directory"
fi

######## Platform Install Scripts ########
SCRIPT_DIR=$(dirname "$(realpath -s "$0")")
source "$SCRIPT_DIR/$(uname | tr '[:upper:]' '[:lower:]').zsh"

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