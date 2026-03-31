S_PLUGINS_DIRECTORY="$HOME/dotfiles/custom/static/zsh-custom/plugins"
S_PLUGINS=(
    zsh-autosuggestions/zsh-autosuggestions.zsh
    zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    zsh-autocomplete/zsh-autocomplete.plugin.zsh
    zsh-completions/zsh-completions.plugin.zsh
    fzf-tab/fzf-tab.zsh
)

for plugin in $S_PLUGINS; do
    source "$S_PLUGINS_DIRECTORY/$plugin"
done

# TODO: Use patina eventually...
# eval "$(~/.cargo/bin/zsh-patina activate)"