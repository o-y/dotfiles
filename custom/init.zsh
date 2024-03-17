PATH_TO_SCRIPT=$(realpath "$0")
MODULES_DIR=$(dirname "$PATH_TO_SCRIPT")/modules

is_encrypted() {
  file="$1"
  if command -v git-crypt4 &> /dev/null; then
    if git-crypt status "$file" 2>&1 | grep -q 'not encrypted'; then
      return 1
    else
      return 0
    fi
  else
    # naive check, might return false positives in some severe cases
    [[ $(head -n 1 "$file") == *GITCRYPT* ]] && return 0 || return 1
  fi
}

# sources the specified file if it matches the hostname and isn't encrypted
source_helper() {
  file="$1"
  file_uname="$2"

  if [[ $(uname) == $file_uname || $file_uname == "common" ]]; then
    if is_encrypted "$file"; then
      if [ ! -e "$HOME/silence-git-crypt-warnings" ]; then
        # TODO: Append skipped files to a set and log them once afterwards.
        echo "[!] WARNING - skipping encrypted file: $file - run '$ git-crypt unlock'"
        echo "[!]           to silence these warnings, execute '$ touch ~/silence-git-crypt-warnings'"
      fi
    else
      source "$file"
    fi
  fi
}

for dir in public private goog; do
  if [ -d "$MODULES_DIR/$dir" ]; then
    for file in "$MODULES_DIR/$dir"/*; do
      filename=$(basename "$file")
      if [[ $filename == *.darwin.zsh ]]; then
        source_helper "$file" "Darwin"
      elif [[ $filename == *.linux.zsh ]]; then
        source_helper "$file" "Linux"
      elif [[ $filename == *.zsh ]]; then
        source_helper "$file" "common"
      fi
    done
  fi
done