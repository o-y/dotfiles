PATH_TO_SCRIPT=$(realpath -s "$0")
MODULES_DIR=$(dirname "$PATH_TO_SCRIPT")/modules

# sources the specified file if it matches the hostname and isn't encrypted
is_encrypted() {
  file="$1"
  if command -v git-crypt &> /dev/null; then
    git-crypt status --encrypted "$file" &> /dev/null
  else
    echo "[init] WARNING - git-crypt not installed on system, delegating to naive check"
    head -n 1 "$file" | grep -q '^GITCRYPT'
  fi
}

source_helper() {
  file="$1"
  file_uname="$2"

  if [[ $(uname) == $file_uname ]]; then
    if ! is_encrypted "$file"; then
      source "$file"
    else
      echo "[init] WARNING - skipping encrypted file: $file"
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
        source "$file"
      fi
    done
  fi
done