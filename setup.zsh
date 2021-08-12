if [[ `uname` == 'Darwin' ]]
then
  brew install stow
elif [[ `uname` == 'Linux' ]]
then
  sudo apt-get install stow
else
    echo "Error! - Unrecognised OS";
    exit 64
fi

echo "Setting up symlinks...";

stow blaze
stow p10k
stow tmux
stow vim
stow yabai
stow zsh
stow skhd