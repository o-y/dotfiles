echo "Press any key to install required dependencies and symlink dotfiles (or ctrl+c to cancel)";
read;

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

  if ! command -v gawk &> /dev/null
  then
    echo "[glinux]: installing gawk..."
    brew install gawk
  fi
elif [[ `uname` == 'Linux' ]]
then
  if ! command -v stow &> /dev/null
  then
    echo "[glinux]: installing stow..."
    sudo apt-get install stow
  fi

  if ! command -v gawk &> /dev/null
  then
    echo "[glinux]: installing gawk..."
    sudo apt-get install gawk
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

echo "Backing up existing files..."
mkdir -p "~/.$USER-dotfiles-backup";
[ -f ~/.blazerc ] && mv ~/.blazerc "~/.$USER-dotfiles-backup";
[ -f ~/.p10k ] && mv ~/.p10k "~/.$USER-dotfiles-backup";
[ -f ~/.tmuxrc ] && mv ~/.tmuxrc "~/.$USER-dotfiles-backup";
[ -f ~/.vimrc ] && mv ~/.vimrc "~/.$USER-dotfiles-backup"
[ -f ~/.yabairc ] && mv ~/.yabairc "~/.$USER-dotfiles-backup";
[ -f ~/.zshrc ] && mv ~/.zshrc "~/.$USER-dotfiles-backup";
[ -f ~/.zshenv ] && mv ~/.zshenv "~/.$USER-dotfiles-backup";
[ -f ~/.skhdrc ] && mv ~/.skhdrc "~/.$USER-dotfiles-backup";

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

echo "Installation complete - existing files have been backed up at $HOME/.$USER-dotfiles-backup. Press any key to restart zsh...";
read;
zsh;
