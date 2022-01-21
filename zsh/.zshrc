#### Set zsh directory and custom directory for plugins
export ZSH_CUSTOM="$HOME/dotfiles/custom/static/zsh-custom"
export ZSH="$HOME/.oh-my-zsh"
export ZSH_THEME="powerlevel10k/powerlevel10k"

#### Assorted configs
export SLYO_SET_CLIENT_AS_TITLE="true"
export PROMPT_EOL_MARK=''
export POWERLEVEL9K_SHORTEN_STRATEGY="truncate_from_right"
export POWERLEVEL9K_SHORTEN_DIR_LENGTH=1
export DISABLE_AUTO_TITLE="true"
export ENABLE_CORRECTION="false"
export COMPLETION_WAITING_DOTS="true"

#### Load custom scripts
source ~/dotfiles/custom/init.zsh

#### PowerLevel instant prompt - this should happen AFTER any output.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

#### Load Zsh
plugins=(git zsh-syntax-highlighting zsh-autosuggestions macos fzf-tab)
source $ZSH/oh-my-zsh.sh

#### Load mdproxy if running on MacOS
if [[ `uname` == 'Darwin' ]]
then
  source $HOME/mdproxy/data/mdproxy_zshrc 

  #### Also mount x20/ - this is causing hanging :/
  # export MDPROXY_EXTRA_MOUNTS="/google/data" 
fi

if [[ `uname` == 'Linux' ]]
then
  source /etc/bash_completion.d/g4d
fi

#### Load PowerLevel10k
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

[[ -e "/Users/slyo/mdproxy/data/mdproxy_zshrc" ]] && source "/Users/slyo/mdproxy/data/mdproxy_zshrc" # MDPROXY-ZSHRC
