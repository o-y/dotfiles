S_PLUGINS_DIRECTORY="$HOME/dotfiles/custom/static/zsh-custom/plugins"
S_PLUGINS=(
    zsh-autocomplete/zsh-autocomplete.plugin.zsh
    zsh-completions/zsh-completions.plugin.zsh
    fzf-tab/fzf-tab.zsh
    zsh-autosuggestions/zsh-autosuggestions.zsh
    zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
)

local -a deferred_plugins

for plugin in $S_PLUGINS; do
    local is_deferred=0
    
    if [[ $plugin == ^* ]]; then
        is_deferred=1
        plugin="${plugin#^}" 
    fi

    target_file="$S_PLUGINS_DIRECTORY/$plugin"
    
    if [[ ! -f "$target_file" ]]; then
        echo "[Warn] Plugin not found: $target_file" >&2
        continue
    fi

    if (( is_deferred )); then
        deferred_plugins+=("$target_file")
    else
        source "$target_file"
    fi
done

_load_deferred_batch() {
    local plugin
    for plugin in "$@"; do
        source "$plugin"
    done
}

if (( ${#deferred_plugins[@]} > 0 )); then
    if (( $+functions[zsh-defer] )); then
        zsh-defer _load_deferred_batch "${deferred_plugins[@]}"
    else
        _load_deferred_batch "${deferred_plugins[@]}"
    fi
fi