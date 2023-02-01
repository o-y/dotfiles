echo "Press any key to install required dependencies and symlink dotfiles (or ctrl+c to cancel)";
read;

echo "Fetching submodule dependencies"
git submodule init;
git submodule update;

# Define commands to check and install for each OS
commands_darwin=(
  "stow" "brew install stow"
  "vim" "brew install vim"
  "gawk" "brew install gawk"
  "realpath" "brew install coreutils"
  "fzf" "brew install fzf"
)

commands_linux=(
  "stow" "sudo apt-get install stow"
  "gawk" "sudo apt-get install gawk"
  "jot" "sudo apt-get install athena-jot"
  "vim" "sudo apt-get install vim"
  "fzf" "sudo apt-get install fzf"
)

if [[ `uname` == 'Darwin' ]]; then
  for ((i=0;i<${#commands_darwin[@]};i+=2)); do
    if ! command -v ${commands_darwin[$i]} &> /dev/null; then
      echo "[osx]: installing ${commands_darwin[$i]}..."
      ${commands_darwin[$i+1]}
    fi
  done
elif [[ `uname` == 'Linux' ]]; then
  for ((i=0;i<${#commands_linux[@]};i+=2)); do
    if ! command -v ${commands_linux[$i]} &> /dev/null; then
      echo "[glinux]: installing ${commands_linux[$i]}..."
      ${commands_linux[$i+1]}
    fi
  done
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
