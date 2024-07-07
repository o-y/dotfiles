########################################
################ CONFIG ################
########################################

# dependencies for MacOS
dependencies_darwin=(
  "stow" "brew install stow"
  "hx" "brew install helix"
  "gawk" "brew install gawk"
  "realpath" "brew install coreutils"
  "fzf" "brew install fzf"
  "scrcpy" "brew install scrcpy"
  "adb" "brew install android-platform-tools"
  "rg" "brew install ripgrep"
  "hyperfine" "brew install hyperfine"
  "git-crypt" "brew install git-crypt"
  "btop" "brew install btop"
  "cliclick" "brew install cliclick"
  "navi" "brew install navi"
  "zoxide" "brew install zoxide"
  "pipx" "brew install pipx"
)

# dependencies for Linux
dependencies_linux=(
  "stow" "sudo apt install stow"
  "gawk" "sudo apt install gawk"
  "jot" "sudo apt install athena-jot"
  "fzf" "sudo apt install fzf"
  "adb" "sudo apt install android-tools-adb"
  "rg" "sudo apt install ripgrep"
  "hyperfine" "sudo apt install hyperfine"
  "git-crypt" "sudo apt install git-crypt"
  "btop" "sudo apt install btop"
  "zoxide" "sudo apt install zoxide"
  "pipx" "sudo apt install pipx"
)

# common symlinks
stows_common=(
  zsh
  zellij:~/.config/zellij
  helix:~/.config/helix
  tmux:~/.config/tmux
  kando:~/.config/kando
)

# symlinks for MacOS
stows_darwin=(skhd yabai)

# symlinks for Linux
stows_linux=(
  blaze
  hgrc
  dunst:~/.config/dunst
  kitty:~/.config/kitty
  hypr:~/.config/hypr
  swaylock:~/.config/swaylock
  rofi:~/.config/rofi
  hypr-empty:~/.config/hypr-empty
  waybar:~/.config/waybar
)

################################################################################
################################################################################
################################################################################

echo "[?] press any key to install required dependencies and symlink dotfiles (or ctrl+c to cancel)";
read -r;

################ Download submodules ################
echo "[~] fetching submodule dependencies";

cd ~/dotfiles || exit

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
      echo "[!] Linux - installing dependency: ${dependencies_linux[$i]}...";
      eval "${dependencies_linux[$i+1]}"
    fi
  done
else
  echo "[!] error - unrecognised OS (${uname})";
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
    stow "$package" --dir="$packages_directory" --target="$target"
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

################# Post install #################
post_install_routine="$HOME/dotfiles/custom/postinstall/common.zsh"
if [ -e $post_install_routine ]; then
    source $post_install_routine
else
    echo "[!] warning - 'post_install_routine' does not exist at $post_install_routine...skipping"
fi

echo "[~] everything successfully (probably) installed and configured! :)"
echo "[?] press any key to reload zsh..."
read -r
zsh
