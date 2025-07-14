#### Required by some TUI apps
# export TERM=xterm-256color

#### Editor
export EDITOR="nvim"

#### GPG
export GPG_TTY=$(tty)

#### Required for Conda which overrides clear - https://askubuntu.com/a/1402408
export TERMINFO=/usr/share/terminfo

#### Zsh History
HISTFILE=~/.zsh_history

# setopt NO_INC_APPEND_HISTORY_TIME
# setopt NO_INC_APPEND_HISTORY
setopt EXTENDED_HISTORY
setopt SHAREHISTORY
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt INC_APPEND_HISTORY_TIME


HISTSIZE=1000000 # In-memory per-session state
SAVEHIST=1000000 # Number of entries to save in ~/.zsh_history