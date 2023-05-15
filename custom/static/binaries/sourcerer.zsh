##########################################
################ Sourcerer ###############
##########################################

echo "[~] starting sourcerer..."
echo "[!] sourcerer: requesting sudo permission which is required to symlink binaries to /usr/local"
sudo -v

if ! sudo -n true &>/dev/null; then
  echo "[!] sourcerer: sudo access denied, exiting..."
  return 1
fi

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
  file_path=$(realpath "$file")
  file_name=$(basename "$file" "-${platform}")
  bin="/usr/local/bin"

  echo "[!] sourcerer: symlinking $file_name (full path: $file) to $bin/$file_name"

  if ! [ -e "$bin/$file_name" ]; then
    sudo chmod +x "$file_path"
    sudo ln -s "$file_path" "$bin/$file_name"
  fi
}

SCRIPT_DIR=$(dirname "$0")

for dir in "$SCRIPT_DIR"/*/; do
  dir=${dir%/}
  file=$(find "$dir" -maxdepth 1 -name "*-${platform}")
  if [[ -n "$file" ]]; then
    source_helper $file
  fi
done