#### Required by some TUI apps
export TERM=xterm-256color

#### Required for iTerm2 + Tmux integration
export ITERM_ENABLE_SHELL_INTEGRATION_WITH_TMUX=YES

#### Editor
export EDITOR="hx"

#### Zsh History
HISTFILE=~/.zsh_history

setopt NO_INC_APPEND_HISTORY_TIME
setopt NO_INC_APPEND_HISTORY

# In-memory per-session state
HISTSIZE=100000

# No. entries to save in ~/.zsh_history
SAVEHIST=100000

setopt EXTENDED_HISTORY
setopt SHAREHISTORY
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY