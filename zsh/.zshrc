#### Set zsh directory and custom directory for plugins
export ZSH_CUSTOM="$HOME/dotfiles/custom/static/zsh-custom"
export ZSH="$HOME/.oh-my-zsh"
export ZSH_THEME="powerlevel10k/powerlevel10k" # relative from ZSH_CUSTOM

#### Assorted configs
export SLYO_SET_CLIENT_AS_TITLE="true"
export TMUX_CONNECT_AUTOMATICALLY_ON_SSH="true"
export PROMPT_EOL_MARK=''
export POWERLEVEL9K_SHORTEN_STRATEGY="truncate_from_right"
export POWERLEVEL9K_SHORTEN_DIR_LENGTH=1
export DISABLE_AUTO_TITLE="true"
export ENABLE_CORRECTION="false"
export COMPLETION_WAITING_DOTS="true"
export ENABLE_CORRECTION="true"

#### Load custom scripts
source ~/dotfiles/custom/init.zsh

#### PowerLevel instant prompt - this should happen AFTER any output.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

#### Add zsh-completions (https://github.com/zsh-users/zsh-completions/issues/603)
fpath+=${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src

#### Load Zsh
plugins=(git fzf-tab zsh-syntax-highlighting zsh-autosuggestions citc)
source $ZSH/oh-my-zsh.sh

#### Load mdproxy if running on MacOS
if [[ `uname` == 'Darwin' ]] then
  [[ -e "$HOME/mdproxy/data/mdproxy_zshrc" ]] && source $HOME/mdproxy/data/mdproxy_zshrc 
fi

#### Load g4d completions on Linux
if [[ `uname` == 'Linux' ]] then
  [[ -e "/etc/bash_completion.d/g4d" ]] && source /etc/bash_completion.d/g4d
fi

#### Load p10k
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

#### The following lines were added by compinstall
zstyle ':completion:*' completer _expand _complete _ignored _correct _approximate
zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]} r:|[.]=** r:|=** l:|=*' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]} r:|[._-]=** r:|=** l:|=*' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]} r:|[._-]=** r:|=** l:|=*' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]} r:|[._-]=** r:|=** l:|=*'
zstyle :compinstall filename '/Users/slyo/.zshrc'
autoload -Uz compinit
compinit
