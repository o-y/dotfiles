########################################
################# SETUP ################
########################################

PATH_TO_SCRIPT=${0:A}
MODULES_DIR=${PATH_TO_SCRIPT:h}/modules
STATIC_LOADER="$HOME/.zsh_static_loader.zsh"

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


# --- Startup Logic ---

if [[ -f "$STATIC_LOADER" ]]; then
  source "$STATIC_LOADER"

  # In the background, check if any watched source is newer than the cached loader.
  {
    local _stale=0
    local _log="$HOME/.zsh_loader_regen.log"

    # Rebuild if:
    # 1. orchestration files change
    # 2. inlined content changes
    # 3. directory structure changes
    local -a _watched=(
      "${PATH_TO_SCRIPT:h}/hooks.zsh"
      "${PATH_TO_SCRIPT:h}/compiler.zsh"
      "$PATH_TO_SCRIPT"
      "$MODULES_DIR"
      "$MODULES_DIR"/**/*.zsh(N)
    )

    local -a _stale_files=( ${^_watched}(Nne:'[[ $REPLY -nt $STATIC_LOADER ]]':) )
    local isStale=${#_stale_files}
    if (( isStale )); then
      _rebuild_loader
      print -r -- "[$(date '+%Y-%m-%dT%H:%M:%S')] zsh-load cache regenerated (sources changed) — run $ exec zsh to apply" \
        >> "$_log"
      
      # Trigger the trap...
      kill -USR1 $$
    fi
  } &!
else
  # Scenario: Cache is missing — generate and source synchronously.
  echo "Generating zsh-load cache..."
  _rebuild_loader
  exec zsh
fi