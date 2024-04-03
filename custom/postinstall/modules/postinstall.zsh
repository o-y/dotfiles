################ Sourcerer ###############
sourcerer_directory="$HOME/dotfiles/custom/static/binaries/sourcerer.zsh"
if [ -e $sourcerer_directory ]; then
    source $sourcerer_directory
else
    echo "[!] warning - sourcerer does not exist at $sourcerer_directory"
fi

################ Install Oh My Zsh ################
if ! [ -e "$HOME/.oh-my-zsh" ]; then
  echo "[!] installing oh-my-zsh";
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc
fi

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

################ Install Rust ################
if ! command -v rustc >/dev/null 2>&1 || ! command -v cargo >/dev/null 2>&1; then
    # echo "[!] rust/cargo is not installed, some dependencies may require that, would you like to install rust?"
    # TODO...
fi