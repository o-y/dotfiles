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