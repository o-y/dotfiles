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
  "pipx" "sudo apt install pipx"
  "bc" "sudo apt install bc"
  "c++" "sudo apt install build-essential"

  ## -- dependencies on cargo --
  "navi:cargo" "cargo install --locked navi"
  "zoxide:cargo" "cargo install zoxide --locked" # the debian stable package is oudated and broken
)

dependencies_common=(
  ## -- dependencies on pipx --
  "fuck:pipx" "pipx install --fetch-missing-python --python "3.11" thefuck" # https://github.com/nvbn/thefuck/issues/1444

  ## -- dependencies on cargo --
  "pik:cargo" "cargo install pik --locked"
  "zellij:cargo" "cargo install zellij --locked"
)

# common symlinks
stows_common=(
  zsh
  zellij:~/.config/zellij
  helix:~/.config/helix
  tmux:~/.config/tmux
  kando:~/.config/kando
  ghostty:~/.config/ghostty
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

function install_dependencies_internal() {
  local dependencies=( "$@" )
  for (( i=1; i<${#dependencies[@]}; i+=2 )); do
    local dependency="${dependencies[$i]}"
    local installer="${dependencies[$i+1]}"

    # state validation: check for multiple colons or spaces
    if [[ "$dependency" == *:*:* || "$dependency" == *" "* ]]; then
      echo "[!] critical - invalid dependency format: '$dependency'. Cannot contain multiple colons or spaces."
      exit 64
    fi

    # check for colon and dependency
    local required_dependency="" # set if there exists a dependent on the right side of the colon
    if [[ "$dependency" == *:* ]]; then
      required_dependency="${dependency##*:}"
      if ! command -v "$required_dependency" &> /dev/null; then
        echo "[!] critical - skipping '$dependency' installation. required dependent '$required_dependency' not found!"
        continue
      fi
      
      dependency="${dependency%:*}"
    fi

    if ! command -v "$dependency" &> /dev/null; then
      if [[ -n "$required_dependency" ]]; then
        echo "[!] installer - installing dependency: ${dependency} (using: $required_dependency)...";
      else
        echo "[!] installer - installing dependency: ${dependency}...";
      fi
      eval "$installer"
    fi
  done
}

function install_dependencies() {
  if [[ $(uname) == 'Darwin' ]]; then
    install_dependencies_internal "${dependencies_darwin[@]}"
  elif [[ $(uname) == 'Linux' ]]; then
    install_dependencies_internal "${dependencies_linux[@]}"
  else
    echo "[!] critical - unrecognised OS (${uname})"
    exit 64
  fi

  install_dependencies_internal "${dependencies_common[@]}"
}

install_dependencies

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

if ! type stow &> /dev/null; then
  echo "[!] critical - missing 'stow' which is a required dependency, terminating early..."
  echo "[!] automatic installation seems to have failed..."
  exit 64
fi

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

    # the post_install_routine might add additional package managers, therefore
    # we call install_dependencies again, this is still quick if the dependencies
    # still can't be installed, so it's okay to call this twice
    echo "[?] checking to see if any additional dependencies can be installed..."
    install_dependencies
else
    echo "[!] warning - 'post_install_routine' does not exist at $post_install_routine...skipping"
fi

echo "[~] everything successfully (probably) installed and configured! :)"
echo "[?] press any key to reload zsh..."
read -r
zsh
