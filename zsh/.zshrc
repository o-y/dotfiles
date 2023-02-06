export PATH=/usr/local/bin:$PATH

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

#### zsh config
# do not append to ~/.zsh_history if command starts with space
setopt HIST_IGNORE_SPACE

#### load custom scripts
source ~/dotfiles/custom/init.zsh

#### load Zsh
plugins=(git fzf-tab zsh-syntax-highlighting zsh-autosuggestions macos)

source $ZSH/oh-my-zsh.sh
