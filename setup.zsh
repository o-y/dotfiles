if ! command -v stow &> /dev/null
then
    echo "Installing stow..."
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
fi

echo "Setting up symlinks...";

stow blaze
stow p10k
stow tmux
stow vim
stow yabai
stow zsh
stow skhd