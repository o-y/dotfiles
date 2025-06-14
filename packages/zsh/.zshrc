#### set zsh directory and custom directory for plugins
export ZSH_CUSTOM="$HOME/dotfiles/custom/static/zsh-custom"
export ZSH="$HOME/.oh-my-zsh"

#### config
export PROMPT_EOL_MARK=''
export DISABLE_AUTO_TITLE="false"
export ENABLE_CORRECTION="false"
export COMPLETION_WAITING_DOTS="true"

#### load Zsh
plugins=(
    fzf-tab
    zsh-syntax-highlighting
    zsh-autosuggestions
    macos
    direnv
)

#### load custom scripts
source ~/dotfiles/custom/init.zsh

source $ZSH/oh-my-zsh.sh
# bun completions
[ -s "/home/zv/.bun/_bun" ] && source "/home/zv/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
