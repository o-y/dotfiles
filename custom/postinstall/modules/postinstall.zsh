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

  # --keep-zshrc prevents ohmyzsh from overwriting the existing zshrc file with their default config
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
    if type git-crypt &> /dev/null; then
        git-crypt unlock;
    else
        echo "[!] error - \$ git-crypt is not installed on your system!"
    fi
fi

################ Install Dependencies ################

# ==============================================================================
# Arguments:
#   $1: Canonical name of the software (e.g., "rust/cargo", "pyenv"). Used in prompts.
#   $2: The command string to execute for installation (e.g., "curl ... | sh").
#   $3..: One or more command names to check for existence (e.g., rustc cargo).
# Usage:
#   ensure_installed "Rust Toolchain" "curl <rustup_url> | sh" rustc cargo
# ==============================================================================
function ensure_installed() {
    if [[ $# -lt 3 ]]; then
        echo "Usage: ensure_installed <canonical_name> <install_command> <command1> [command2...]" >&2
        return 1
    fi

    local canonical_name="$1"
    local install_cmd="$2"
    shift 2
    local cmds_to_check=("$@")

    local missing_cmds=()
    local all_found=1

    for cmd in "${cmds_to_check[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_cmds+=("$cmd")
            all_found=0
        fi
    done

    if [[ $all_found -eq 0 ]]; then
        echo "[!] $canonical_name does not seem to be installed or fully available."

        local answer
        read -q "answer?install $canonical_name? [Y/n] "
        echo

        if [[ $answer == "y" || $answer == "Y" || $answer == "" ]]; then
            echo "[~] attempting to install: $canonical_name..."
            if eval "$install_cmd"; then
                 echo "[~] $canonical_name installation command executed successfully."
            else
                 echo "[!] $canonical_name installation command failed (exit code: $?)." >&2
            fi
        else
            echo "[i] skipping installation of: $canonical_name."
        fi
    fi

    return 0
}

################ Install Rust ################
ensure_installed "rust/cargo" \
                 "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh" \
                 rustc cargo

################ Install Python Dependencies ################
ensure_installed "pyenv" \
                 "curl -fsSL https://pyenv.run | bash" \
                 pyenv

### not sure if we have a license for miniconda, maybe delegate to conda-forge on corp.
if [[ $(hostname) != *corp.google.com && $(hostname) != *c.googlers.com ]]; then
    ensure_installed "miniconda" \
                    "mkdir -p ~/miniconda3 && wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda3/miniconda.sh && bash ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3 && rm ~/miniconda3/miniconda.sh" \
                    conda
fi

ensure_installed "pixi" \
                 "export PIXI_NO_PATH_UPDATE=true && curl -fsSL https://pixi.sh/install.sh | sh" \
                 pixi