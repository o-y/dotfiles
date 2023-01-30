PATH_TO_SCRIPT=$(realpath -s "$0")
MODULES_DIR=$(dirname "$PATH_TO_SCRIPT")/modules

for dir in public private goog; do
  if [ -d "$MODULES_DIR/$dir" ]; then
    for file in "$MODULES_DIR/$dir"/*; do
      source "$file"
    done
  fi
done