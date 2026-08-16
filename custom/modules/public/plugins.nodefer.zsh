local S_PLUGINS_DIRECTORY="$HOME/dotfiles/custom/static/zsh-custom/plugins"
local S_PLUGINS=(
    # ---- Syntax highlighting
    "^zsh-patina/zsh-patina.zsh || ^zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
    
    # ---- Completions
        # ~ Registry
       "^zsh-completions/zsh-completions.plugin.zsh"

        # ~ Inline ghost completions
        "^zsh-autosuggestions/zsh-autosuggestions.zsh || ^deja/deja.zsh"

        # ~ Live completions
        "^zsh-autocomplete/zsh-autocomplete.plugin.zsh"
    
        # ~ Fig-like completions
        # "iris/iris.zsh"

        # Completions on tab
        "^fzf-tab/fzf-tab.zsh"
)

local -a deferred_plugins

_source_plugin() {
    local entry="$1"
    # Parse candidate fallbacks (supports infinite || chains)
    local -a candidates=("${(@s/||/)entry}")
    local candidate target_file
    
    for candidate in "${candidates[@]}"; do
        # 1. Strip whitespace
        candidate="$(echo "$candidate" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
        # 2. Strip the leading '^' from the individual candidate to ensure a clean file path
        candidate="${candidate#^}"
        
        target_file="$S_PLUGINS_DIRECTORY/$candidate"
        
        if [[ ! -f "$target_file" ]]; then
            continue
        fi
        
        if source "$target_file"; then
            return 0
        else
            echo "[!] plugin :: initialisation failed for: $candidate. trying fallback..." >&2
        fi
    done
    
    return 1
}

for plugin_entry in "${S_PLUGINS[@]}"; do
    local is_deferred=0
    
    # Check if the string starts with ^, OR if any fallback starts with ^
    if [[ $plugin_entry == ^* ]] || [[ $plugin_entry == *"|| ^"* ]] || [[ $plugin_entry == *"||^"* ]]; then
        is_deferred=1
    fi

    if (( is_deferred )); then
        deferred_plugins+=("$plugin_entry")
    else
        if ! _source_plugin "$plugin_entry"; then
            echo "[Error] All candidates failed for plugin entry: $plugin_entry" >&2
        fi
    fi
done

_load_deferred_batch() {
    local entry
    for entry in "$@"; do
        if ! _source_plugin "$entry"; then
            echo "[Error] All deferred candidates failed for plugin entry: $entry" >&2
        fi
    done
}

if (( ${#deferred_plugins[@]} > 0 )); then
    if (( $+functions[zsh-defer] )); then
        zsh-defer _load_deferred_batch "${deferred_plugins[@]}"
    else
        _load_deferred_batch "${deferred_plugins[@]}"
    fi
fi