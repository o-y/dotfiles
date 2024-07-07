########################################
################# SETUP ################
########################################

PATH_TO_SCRIPT=$(realpath "$0")
MODULES_DIR=$(dirname "$PATH_TO_SCRIPT")/modules

# files which are skipped due to being encrypted
skipped_files=()

# determines whether a file is encrypted using git-crypt
is_encrypted() {
  file="$1"
  [[ $(head -n 1 "$file") == *GITCRYPT* ]] && return 0 || return 1
}

# sources the specified file if it matches the hostname and isn't encrypted
source_helper() {
  file="$1"
  file_uname="$2"

  if [[ $(uname) == $file_uname || $file_uname == "common" ]]; then
    if is_encrypted "$file"; then
      skipped_files+=("$file")
    else
      source "$file"
    fi
  fi
}

###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~###

# source priority config
source "$(dirname "$PATH_TO_SCRIPT")/priority_init.zsh"

# source modules
all_zsh_files=("$MODULES_DIR"/{public,private,goog}/**/*.zsh)

for file in "${all_zsh_files[@]}"; do
  filename=$(basename "$file")
  if [[ $filename == *.darwin.zsh ]]; then
    source_helper "$file" "Darwin"
  elif [[ $filename == *.linux.zsh ]]; then
    source_helper "$file" "Linux"
  elif [[ $filename == *.zsh ]]; then
    source_helper "$file" "common"
  fi
done

# output the skipped files list if there are any
if [[ ${#skipped_files[@]} -gt 0 && ! -e "$HOME/silence-git-crypt-warnings" && ! -e "$HOME/.silence-git-crypt-warnings" ]]; then
  echo "[!] WARNING: The following encrypted files were skipped:"
  echo "[!] --- ↓"
  for file in "${skipped_files[@]}"; do
      echo "[!]     $file"
  done
  echo "[!] --- ↑"
  echo "[!] Run '$ git-crypt unlock' to decrypt them."
  echo "[!] To silence these warnings, execute '$ touch ~/.silence-git-crypt-warnings'"
fi
