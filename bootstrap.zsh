########################################
################ CONFIG ################
########################################

# dependencies for MacOS
dependencies_darwin=(
  "stow" "brew install stow"
  "vim" "brew install vim"
  "gawk" "brew install gawk"
  "realpath" "brew install coreutils"
  "fzf" "brew install fzf"
  "scrcpy" "brew install scrcpy"
  "adb" "brew install android-platform-tools"
  "rg" "brew install ripgrep"
)

# dependencies for Linux
dependencies_linux=(
  "stow" "sudo apt-get install stow"
  "gawk" "sudo apt-get install gawk"
  "jot" "sudo apt-get install athena-jot"
  "vim" "sudo apt-get install vim"
  "fzf" "sudo apt-get install fzf"
  "scrcpy" "sudo apt-get install scrcpy"
  "adb" "sudo apt-get install android-tools-adb"
  "rg" "sudo apt-get install ripgrep"
)

# common symlinks
stows_common=(
  zsh
  nvim:~/.config/nvim
)

# symlinks for MacOS
stows_darwin=(skhd yabai)

# symlinks for Linux
stows_linux=(blaze)

################################################################################
################################################################################
################################################################################

echo "[?] press any key to install required dependencies and symlink dotfiles (or ctrl+c to cancel)";
read -r;

################ Install Oh My Zsh ################
echo "[!] installing oh-my-zsh";
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

################ Download submodules ################
echo "[~] fetching submodule dependencies";

cd ~/dotfiles || exit

rm ~/.zshrc
rm ~/.blazerc
rm ~/.tmux
rm -rf ~/config/nvim

git submodule init;
git submodule sync;
git submodule update;
git submodule status;

################ Install dependencies ################
echo "[~] installing required dependencies...";
if [[ $(uname) == 'Darwin' ]]; then
  for ((i=1;i<${#dependencies_darwin[@]};i+=2)); do
    if ! command -v ${dependencies_darwin[$i]} &> /dev/null; then
      echo "[!] OSX - installing dependency: ${dependencies_darwin[$i]}...";
      eval "${dependencies_darwin[$i+1]}"
    fi
  done
elif [[ $(uname) == 'Linux' ]]; then
  for ((i=1;i<${#dependencies_linux[@]};i+=2)); do
    if ! command -v ${dependencies_linux[$i]} &> /dev/null; then
      echo "[!] gLinux - installing dependency: ${dependencies_linux[$i]}...";
      eval "${dependencies_linux[$i+1]}"
    fi
  done
else
  echo "[!] error - unrecognised OS";
  exit 64;
fi

################ Setup dotfile symlinks ################
echo "[~] setting up dotfile symlinks...";

packages_directory="$HOME/dotfiles/packages"
target="$HOME"

process_stows() {
  local -a stows=("$@")

  for stow in "${stows[@]}"; do
    IFS=':' read -r package target <<< "$stow"
    if [[ -z "$target" ]]; then
      target="$HOME"
    fi
    echo "[!] symlinking '$package' from '$packages_directory' to '$target'"

    mkdir -p "$target"
    stow "$package" --dir="$packages_directory" --target="$target" --adopt
  done
}

if [[ $(uname) == "Darwin" ]]; then
  # MacOS Stows
  process_stows "${stows_darwin[@]}"
elif [[ $(uname) == "Linux" ]]; then
  # Linux Stows
  process_stows "${stows_linux[@]}"
fi

# Common Stows
process_stows "${stows_common[@]}"

################ Post install :D ################
echo "[~] everything successfully (probably) installed and configured! :)"
echo "[?] press any key to continue..."
read -r
zsh