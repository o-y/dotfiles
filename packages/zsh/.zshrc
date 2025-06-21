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

source $ZSH/oh-my-zsh.sh

#### load custom scripts
source ~/dotfiles/custom/init.zsh
# TODO: Swap the order round after fixing the issue with oh-my-zsh breaking fpath completions.
