#### Required by some TUI apps
# NOTE: This is now handled by Ghostty which forwards this variable to remotes as well.
# If commands such as 'clear' start failing, this is probably because the terminfo is
# missing, in which case, try running:
# TERMINFO="/Applications/Ghostty.app/Contents/Resources/terminfo" infocmp -x xterm-ghostty | tic -x -
export TERM=xterm-ghostty

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