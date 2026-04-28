########################################
################# SETUP ################
########################################

PATH_TO_SCRIPT=${0:A}
MODULES_DIR=${PATH_TO_SCRIPT:h}/modules
STATIC_LOADER="$HOME/.zsh_static_loader.zsh"
EAGERLY_INIT_DOTFILES="$HOME/.eagerly_init_zsh_static_loader"

# --- Helpers ---

# Sources the orchestration files and (re)generates the static loader.
_rebuild_loader() {
  source "${PATH_TO_SCRIPT:h}/hooks.zsh"
  source "${PATH_TO_SCRIPT:h}/compiler.zsh"
  generate_static_loader
}

# --- Trap to hook logs back to the stdout
TRAPUSR1() {
  _notify_cache_regen() {
    zle && zle -M "[dotfiles] zsh cache regenerated - run 'exec zsh' to apply or any command to dismiss"
  }

  # If possible, post to zsh-defer so the function is executed at the end of the queue
  if (( $+functions[zsh-defer] )); then
    zsh-defer -12pr _notify_cache_regen
  else
    _notify_cache_regen
  fi
}

# Evaluates if watched sources are newer than the cache, and rebuilds if needed.
_check_and_rebuild() {
  local is_sync=$1
  local -a watched=(
    "${PATH_TO_SCRIPT:h}/hooks.zsh"
    "${PATH_TO_SCRIPT:h}/compiler.zsh"
    "$PATH_TO_SCRIPT"
    "$MODULES_DIR"
    "$MODULES_DIR"/**/*.zsh(N)
  )

  # Expand and filter for files newer than the cache (-nt)
  local -a stale_files=( ${^watched}(Nne:'[[ $REPLY -nt $STATIC_LOADER ]]':) )

  # Exit early if cache is fully up-to-date
  (( ${#stale_files} == 0 )) && return 0

  if (( is_sync )); then
    echo "zsh-load cache is out-of-date. Regenerating synchronously..."
    _rebuild_loader
    exec zsh
  else
    local log_file="$HOME/.zsh_loader_regen.log"
    _rebuild_loader
    print -r -- "[$(date '+%Y-%m-%dT%H:%M:%S')] zsh-load cache regenerated (sources changed) — run 'exec zsh' to apply" \
      >> "$log_file"
    
    # Signal the parent shell
    kill -USR1 $$
  fi
}

# --- Startup Logic ---

if [[ ! -f "$STATIC_LOADER" ]]; then
  # Scenario 1: Cache is entirely missing
  echo "Generating zsh-load cache..."
  _rebuild_loader
  exec zsh
elif [[ -f "$EAGERLY_INIT_DOTFILES" ]]; then
  # Scenario 2: Eager initialization synchronously
  _check_and_rebuild true
  source "$STATIC_LOADER"
else
  # Scenario 3: Lazy initialization
  source "$STATIC_LOADER"
  _check_and_rebuild false &!
fi