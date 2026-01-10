S_PLUGINS_DIRECTORY="$HOME/dotfiles/custom/static/zsh-custom/plugins"
S_PLUGINS=(
    zsh-autosuggestions/zsh-autosuggestions.zsh
    zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    fzf-tab/fzf-tab.zsh
)

for plugin in $S_PLUGINS; do
    zsh-defer source "$S_PLUGINS_DIRECTORY/$plugin"
done