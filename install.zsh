echo "Fetching submodule dependencies"
git submodule init;
git submodule update;

if [[ `uname` == 'Darwin' ]]
then
  if ! command -v stow &> /dev/null
  then
    echo "[osx]: installing stow..."
    brew install stow
  fi

  if ! command -v vim &> /dev/null
  then
    echo "[osx]: installing vim..."
    brew install vim
  fi
elif [[ `uname` == 'Linux' ]]
then
  if ! command -v stow &> /dev/null
  then
    echo "[glinux]: installing stow..."
    sudo apt-get install stow
  fi

  if ! command -v jot &> /dev/null
  then
    echo "[glinux]: installing jot..."
    sudo apt-get install athena-jot
  fi

  if ! command -v vim &> /dev/null
  then
    echo "[glinux]: installing vim..."
    sudo apt-get install vim
  fi
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

echo "Installing and setting up Vim plug...";
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

vim +'PlugInstall --sync' +qa

echo "Installation complete. Press any key to restart zsh...";
read;
zsh;