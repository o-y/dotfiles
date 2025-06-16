########################################
################# SETUP ################
########################################

PATH_TO_SCRIPT=${0:A}
MODULES_DIR=${PATH_TO_SCRIPT:h}/modules

# load modules
zmodload zsh/mathfunc

# add hooks to the context
source "${PATH_TO_SCRIPT:h}/hooks.zsh"

# files which are skipped due to being encrypted
skipped_files=()

# determines whether a file is encrypted using git-crypt
function is_encrypted {
  [[ -r "$1" && $(head -n 1 "$1") == *GITCRYPT* ]]
}

# sources the specified file if it matches the hostname and isn't encrypted
uname=$(uname)
function source_helper() {
  local file=$1
  local file_uname=$2

  if [[ $uname == $file_uname || $file_uname == "common" ]]; then
    if is_encrypted "$file"; then
      skipped_files+="$file"
    else
      source "$file"
    fi
  fi
}

###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~###

zsh_pre_init;

# source modules
for file in $MODULES_DIR/{public,private,goog}/**/*.zsh(N); do
  case $file:e in
    darwin.zsh) source_helper "$file" "Darwin" ;;
    linux.zsh) source_helper "$file" "Linux" ;;
    zsh) source_helper "$file" "common" ;;
  esac
done

# output the skipped files list if there are any
if (( ${#skipped_files} > 0 )) && [[ ! -e "$HOME/silence-git-crypt-warnings" && ! -e "$HOME/.silence-git-crypt-warnings" ]]; then
  echo "[!] WARNING: The following encrypted files were skipped:"
  echo "[!] --- ↓"
  for file in $skipped_files; do
    echo "[!]     $file"
  done
  echo "[!] --- ↑"
  echo "[!] Run '$ git-crypt unlock' to decrypt them."
  echo "[!] To silence these warnings, execute '$ touch ~/.silence-git-crypt-warnings'"
fi

zsh_post_init;