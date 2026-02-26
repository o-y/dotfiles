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

# --- Startup Logic ---

if [[ -f "$STATIC_LOADER" ]]; then
  source "$STATIC_LOADER"

  # In the background, check if any watched source is newer than the cached loader.
  # If so, regenerate it and log — the user will need to `exec zsh` to pick it up.
  {
    local _stale=0
    local _log="$HOME/.zsh_loader_regen.log"

    # Rebuild if:
    # 1. Orchestration files change (hooks, compiler, init)
    # 2. Inlined content changes (dependencies/ OR *.nodefer.*)
    # 3. Directory structure changes (new/deleted modules)
    local -a _watched=(
      "${PATH_TO_SCRIPT:h}/hooks.zsh"
      "${PATH_TO_SCRIPT:h}/compiler.zsh"
      "$PATH_TO_SCRIPT"
      "$MODULES_DIR"
      "$MODULES_DIR"/dependencies/**/*.zsh(N)
      "$MODULES_DIR"/**/*.nodefer.*.zsh(N)
      "$MODULES_DIR"/**/*.nodefer.zsh(N)
    )

    local -a _stale_files=( ${^_watched}(Nne:'[[ $REPLY -nt $STATIC_LOADER ]]':) )
    local isStale=${#_stale_files}
    if (( isStale )); then
      _rebuild_loader
      print -r -- "[$(date '+%Y-%m-%dT%H:%M:%S')] zsh-load cache regenerated (sources changed) — run \`exec zsh\` to apply" \
        >> "$_log"
    fi
  } &!

else
  # Scenario: Cache is missing — generate and source synchronously.
  echo "Generating zsh-load cache..."
  _rebuild_loader
fi