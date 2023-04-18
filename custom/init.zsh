PATH_TO_SCRIPT=$(realpath -s "$0")
MODULES_DIR=$(dirname "$PATH_TO_SCRIPT")/modules

# sources the specified file if it matches the hostname
source_helper() {
  file="$1"
  file_uname="$2"

  if [[ $(uname) == $file_uname ]]; then
    source "$file"
  fi;
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