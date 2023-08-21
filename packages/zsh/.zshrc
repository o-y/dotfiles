#### set zsh directory and custom directory for plugins
export ZSH_CUSTOM="$HOME/dotfiles/custom/static/zsh-custom"
export ZSH="$HOME/.oh-my-zsh"

#### assorted configs
export SLYO_SET_CLIENT_AS_TITLE="true"
export TMUX_CONNECT_AUTOMATICALLY_ON_SSH="true"
export PROMPT_EOL_MARK=''
export POWERLEVEL9K_SHORTEN_STRATEGY="truncate_from_right"
export POWERLEVEL9K_SHORTEN_DIR_LENGTH=1
export DISABLE_AUTO_TITLE="true"
export ENABLE_CORRECTION="false"
export COMPLETION_WAITING_DOTS="true"
export ENABLE_CORRECTION="false"

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

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/Users/zv/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/Users/zv/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/Users/zv/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/Users/zv/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

