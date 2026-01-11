########################################
################# SETUP ################
########################################

PATH_TO_SCRIPT=${0:A}
MODULES_DIR=${PATH_TO_SCRIPT:h}/modules
STATIC_LOADER="$HOME/.zsh_static_loader.zsh"

# --- Startup Logic ---

# Find if any critical files or directories have changed.
if [[ ! -f "$STATIC_LOADER" ]]; then
  # Scenario: Cache is missing - generate and source synchronously
  source "${PATH_TO_SCRIPT:h}/hooks.zsh"
  source "${PATH_TO_SCRIPT:h}/compiler.zsh"

  echo "Generating zsh-load cache..."
  generate_static_loader
elif [[ -z "$ZSH_EXECUTION_STRING" ]]; then
  # Scenario: Interactive shell - check for structural updates
  if [[ -n "$(find "$MODULES_DIR" -type d -newer "$STATIC_LOADER" -print -quit 2>/dev/null)" || \
        "${PATH_TO_SCRIPT:h}/hooks.zsh" -nt "$STATIC_LOADER" || \
        "${PATH_TO_SCRIPT:h}/compiler.zsh" -nt "$STATIC_LOADER" || \
        "${PATH_TO_SCRIPT:h}/init.zsh" -nt "$STATIC_LOADER" || \
        "$PATH_TO_SCRIPT" -nt "$STATIC_LOADER" ]]; then
    
    source "${PATH_TO_SCRIPT:h}/hooks.zsh"
    source "${PATH_TO_SCRIPT:h}/compiler.zsh"
    
    echo "Regenerating zsh-load cache..."
    generate_static_loader
  fi
fi

source "$STATIC_LOADER"