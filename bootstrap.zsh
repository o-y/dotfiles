##############################################
################ DEPENDENCIES ################
##############################################

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
  "curl" "sudo apt install curl"

  ## -- dependencies on cargo --
  "zoxide:cargo" "cargo install zoxide --locked" # the debian stable package is oudated and broken
)

dependencies_common=(
  ## -- dependencies on pipx --
  "poetry:pipx" "pipx install poetry"

  ## -- dependencies on cargo --
  "pik:cargo" "cargo install pik --locked"
  "zellij:cargo" "cargo install zellij --locked"
  "atuin:cargo" "cargo install atuin --locked"
)

#########################################
################# STOWS #################
#########################################

function is_google() [[ "$(hostname)" =~ '\.corp\.goo(gle|glers)\.com$' ]]
function is_macos() [[ "$(uname)" == "Darwin" ]]
function is_linux() [[ "$(uname)" == "Linux" ]]

# common symlinks
stows_common=(
  "zsh"
  "git"

  "zellij:~/.config/zellij"
  "helix:~/.config/helix"
  "kando:~/.config/kando"
  "nvim:~/.config/nvim"
  "sesh:~/.config/sesh"

  # # jj config
  "jj/google    when: is_google"
  "jj/personal  when: ! is_google"

  # tmux config
  "tmux/config" # for some stupid reason, tpm only works if the config exists at ~/.tmux.conf
  "tmux/base/plugins:~/.tmux/plugins"
  "tmux/base/config:~/.tmux"

  # ---- ghostty ----
  # as "linux" and "macos" represent scoped-configuration
  # these are conditionally stowed. the themes, shaders
  # and base config are conditional, therefore we can
  # stow them straight into the ~/.config/ghostty directory.
  "ghostty/base:~/.config/ghostty"
  "ghostty/themes:~/.config/ghostty/themes"
  "ghostty/shaders:~/.config/ghostty/shaders"
  # ghostty/linux and ghostty/macos are conditionally stowed
  # and contain files named "platform-config" which are
  # sourced by ghostty (if they exist).
  "ghostty/linux:~/.config/ghostty when: is_linux"
  "ghostty/macos:~/.config/ghostty when: is_macos"
)

# symlinks for MacOS
stows_darwin=(
  skhd
  yabai
  aerospace:~/.config/aerospace
)

# symlinks for Linux
stows_linux=(
  blaze
  hgrc

  dunst:~/.config/dunst
  kitty:~/.config/kitty
  hypr:~/.config/hypr
  swaylock:~/.config/swaylock
  rofi:~/.config/rofi
  waybar:~/.config/waybar
)

################################################################################
################################################################################
################################################################################

echo "[?] core :: press any key to install required dependencies and symlink dotfiles (or ctrl+c to cancel)";
read -r;

################ Download submodules ################
echo "[~] core :: fetching submodule dependencies";

cd ~/dotfiles || exit

git submodule init;
git submodule sync;
git submodule update;
git submodule status;

################ Install dependencies ################
echo "[~] depman :: installing required dependencies...";

function install_dependencies_internal() {
  local dependencies=( "$@" )
  for (( i=1; i<${#dependencies[@]}; i+=2 )); do
    local dependency="${dependencies[$i]}"
    local installer="${dependencies[$i+1]}"

    # state validation: check for multiple colons or spaces
    if [[ "$dependency" == *:*:* || "$dependency" == *" "* ]]; then
      echo "[!] depman :: critical - invalid dependency format: '$dependency'. Cannot contain multiple colons or spaces."
      exit 64
    fi

    # check for colon and dependency
    local required_dependency="" # set if there exists a dependent on the right side of the colon
    if [[ "$dependency" == *:* ]]; then
      required_dependency="${dependency##*:}"
      if ! command -v "$required_dependency" &> /dev/null; then
        echo "[!] depman :: critical - skipping '$dependency' installation. required dependent '$required_dependency' not found!"
        continue
      fi
      
      dependency="${dependency%:*}"
    fi

    if ! command -v "$dependency" &> /dev/null; then
      if [[ -n "$required_dependency" ]]; then
        echo "[~] depman :: installer - installing dependency: ${dependency} (using: $required_dependency)...";
      else
        echo "[~] depman :: installer - installing dependency: ${dependency}...";
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
    echo "[!] depman :: critical - unrecognised OS (${uname})"
    exit 64
  fi

  install_dependencies_internal "${dependencies_common[@]}"
}
install_dependencies

################ Setup dotfile symlinks ################
echo "[~] stower :: setting up dotfile symlinks...";

function process_stows() {
  ## Format: "pkg[:target] [when:condition_cmd]"
  ## Example: "pkg:~/.config when:command"
  ## Example: "pkg when:command"
  ## Example: "pkg:~/.config" (no condition)
  ## Example: "pkg" (no condition, default target is $HOME)

  # trims leading and trailing spaces from a string
  function trim() { echo "$1" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'; }

  for stow_entry in "$@"; do
    local stow_segment="$stow_entry"
    local packages_directory="$HOME/dotfiles/packages"

    ##
    ## detect and parse the optional "... [when:condition]" clause
    ##
    if [[ "$stow_entry" == *' when:'* ]]; then
      stow_segment="${stow_entry%%' when:'*}"     # part before " when:"
      stow_predicate="${stow_entry#*' when:'}"    # part after "when:"
      stow_predicate="$(trim $stow_predicate)"    # trim leading/trailing spaces

      # validate: ensure stow_segment (package[:target]) is not empty after the split
      if [[ -z "$stow_segment" ]]; then
        echo "[!] stower :: critical - skipping - empty package/target part for conditional stow entry '$stow_entry'."
        continue
      fi
      
      # validate: ensure stow_predicate is not empty after the split
      if [[ -z "$stow_predicate" ]]; then
        echo "[!] stower :: critical - skipping - empty condition for '$stow_segment' in entry '$stow_entry'."
        continue
      fi

      # execute the stow_predicate and continue if the execute code is zero
      if ! eval "$stow_predicate"; then
        continue
      fi
    fi

    ##
    ## detect and parse the optional "...:target" clause (such as "pkg:~/.config")
    ##
    local package="$(trim $stow_segment)"
    local target_dir="$HOME"

    if [[ "$stow_segment" == *:* ]]; then
      package="${stow_segment%%:*}"           # part before the first ':'
      target_dir="${stow_segment#*:}"         # part after the first ':'
      target_dir="$(trim $target_dir)"        # trim leading/trailing spaces
      target_dir="${target_dir/#\~/$HOME}"    # resolve ~ to $HOME
    fi

    ##
    ## adjust the effective stow directory and package name if 'package' contains slashes.
    ## this allows specifying packages in subdirectories such as "cluster/subpackage".
    ## stow requires the package name argument to be a direct child the input directory.
    ## for example this would transform "jj/personal:~" into:
    ##   - package: "personal"
    ##   - from: "$packages_directory/jj"
    ##   - to: "$HOME"
    ##
    if [[ "$package" == */* ]]; then    
      local final_stow_pkg_name="${package##*/}"   # package name: top part after the last slash     - foo/bar/[baz] -> baz
      local package_subpath="${package%/*}"        # package subpath: top part before the last slash - [foo/bar]/baz -> foo/bar
      local final_stow_pkg_dir="$packages_directory/$package_subpath"
      
      echo "[~] stower :: path-like package '$package' detected. promoting the top subpath ('$final_stow_pkg_name') as its own package under dir: '${package_subpath}'."

      package="$final_stow_pkg_name"
      packages_directory="$final_stow_pkg_dir"
    fi

    # validate: ensure provided package is not empty
    if [[ -z "$package" ]]; then
      echo "[!] stower :: critical - skipping - empty package name derived from '$stow_segment' in entry '$stow_entry'."
      continue
    fi

    # validate: ensure target_dir is not empty
    if [[ -z "$target_dir" ]]; then
      echo "[!] stower :: critical - skipping - explicitly set empty target directory for '$package' in entry '$stow_entry'."
      continue
    fi
    
    # validate: ensure package directory exists
    if [[ ! -d "$packages_directory/$package" ]]; then
      echo "[!] stower :: critical - skipping - directory '$packages_directory/$package' not found."
      continue
    fi
  
    # validate: ensure target_dir is created or writable
    if ! mkdir -p "$target_dir"; then
      echo "[!] stower :: critical - skipping - could not create target directory '$target_dir' for package '$parsed_package'."
      continue
    fi

    # execute the stow command
    if stow "$package" --dir="$packages_directory" --target="$target_dir" 2> /dev/null; then
      echo "[~] stower :: symlinked '$package' from '$packages_directory' to '$target_dir'."
    else
      echo "[!] stower :: critical - failed to symlink '$package' from '$packages_directory' to '$target_dir'."
    fi
  done
}

if ! type stow &> /dev/null; then
  echo "[!] stower :: critical - missing 'stow' which is a required dependency, terminating early..."
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
    echo "[?] depman :: checking to see if any additional dependencies can be installed..."
    install_dependencies
else
    echo "[!] core :: warning - 'post_install_routine' does not exist at $post_install_routine...skipping"
fi

echo "[~] core :: everything successfully (probably) installed and configured! :)"
echo "[?] core :: press any key to reload zsh..."
read -r
zsh
