##########################################
################ Sourcerer ###############
##########################################

echo "[~] starting sourcerer..."

#################### init ####################

os=$(uname -s)
arch=$(uname -m)

if [[ "$os" == "Darwin" ]]; then
  platform="macos-x86_64"
elif [[ "$os" == "Linux" && "$arch" == "x86_64" ]]; then
  platform="linux-x86_64"
elif [[ "$os" == "Linux" && "$arch" == "aarch64" ]]; then
  platform="linux-aarch64"
else
  echo "[!] sourcerer: unknown OS ($os) or architecture ($arch)"
  return 1
fi

source_helper() {
  file=$1
  file_path=$(realpath "$file")
  file_name=$(basename "$file" "-${platform}")
  bin="/usr/local/bin"

  echo "[!] sourcerer: symlinking $file_name (full path: $file) to $bin/$file_name"

  if ! [ -e "$bin/$file_name" ]; then

    # vvv - request sudo permission - vvv
    echo "[!] sourcerer: requesting sudo permission which is required to symlink binaries to /usr/local"
    sudo -v

    if ! sudo -n true &>/dev/null; then
      echo "[!] sourcerer: sudo access denied, exiting..."
      return 1
    fi
    # ^^^ - request sudo permission - ^^^

    sudo chmod +x "$file_path"
    sudo ln -s "$file_path" "$bin/$file_name"
  fi
}

SCRIPT_DIR=$(dirname "$0")

for dir in "$SCRIPT_DIR"/*/; do
  dir=${dir%/}
  basename=${dir##*/}

  echo "[~] sourcerer: scanning binaries in $dir"

  file_with_platform=$(find "$dir" -maxdepth 1 -name "*-${platform}")
  if [[ -n "$file_with_platform" ]]; then
    # If there's a file which includes a $binary-$platform
    source_helper $file_with_platform
  else
    # otherwise look for just the $binary
    if [[ -f "$dir/$basename" ]]; then
      source_helper "$dir/$basename"
    fi
  fi
done