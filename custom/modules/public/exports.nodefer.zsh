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

setopt AUTO_PUSHD              # Make cd push the old directory onto the directory stack
setopt PUSHD_IGNORE_DUPS       # Do not push multiple copies of the same directory onto the stack
setopt PUSHD_SILENT            # Do not print the directory stack after pushd or popd
setopt NO_BEEP                 # Disable terminal bell on ZLE errors

#### Zsh History
HISTFILE=~/.zsh_history

setopt EXTENDED_HISTORY         # Record timestamp and execution duration in $HISTFILE
setopt APPEND_HISTORY           # Append to $HISTFILE rather than overwriting it
setopt INC_APPEND_HISTORY       # Write each command to $HISTFILE immediately on Enter
setopt INTERACTIVE_COMMENTS     # Allow '#' comments inside interactive terminal sessions
setopt HIST_IGNORE_SPACE        # Do not record commands that start with a leading space

HISTSIZE=1000000 # In-memory per-session state
SAVEHIST=1000000 # Number of entries to save in ~/.zsh_history

#### CD'ing
setopt autocd

#### Don't error on comments in the interactive shell
setopt INTERACTIVE_COMMENTS