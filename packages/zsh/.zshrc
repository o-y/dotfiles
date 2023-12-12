#### set zsh directory and custom directory for plugins
export ZSH_CUSTOM="$HOME/dotfiles/custom/static/zsh-custom"
export ZSH="$HOME/.oh-my-zsh"

#### config
export PROMPT_EOL_MARK=''
export DISABLE_AUTO_TITLE="true"
export ENABLE_CORRECTION="true"
export COMPLETION_WAITING_DOTS="true"

#### load custom scripts
source ~/dotfiles/custom/init.zsh

#### load Zsh
plugins=(
    fzf-tab
    zsh-syntax-highlighting
    zsh-autosuggestions
    macos
    adb
    web-search
)

source $ZSH/oh-my-zsh.sh