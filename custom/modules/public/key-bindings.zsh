##########
### SETUP
##########

# Ensure precmds are run after cd
fzf-redraw-prompt() {
  local precmd
  for precmd in $precmd_functions; do
    $precmd
  done
  zle reset-prompt
}
zle -N fzf-redraw-prompt

#########################################
#########################################
### CTRL-Z - Search for files/directories
#########################################
#########################################
 
function zoxide-filepicker {
  __zoxide_zi < "$TTY"
  zle reset-prompt
}
zle -N zoxide-filepicker
bindkey '^Z' zoxide-filepicker

###########################################
###########################################
### CTRL-S - Tmux session manager
###########################################
###########################################
function tmux-session-manager {
  # Renamed 'session' to 'selected_session' to avoid conflicts
  local selected_session=$(sesh list --tmux --hide-attached --icons | fzf-tmux -p 100%,60% \
      --no-sort --ansi \
      --prompt=' ' --border="rounded" --border-label="<  >" --color="label:#caaafe" \
      --bind 'tab:down,btab:up' \
      --bind 'ctrl-a:change-prompt(⚡  )+reload(sesh list --icons)' \
      --bind 'ctrl-t:change-prompt(🪟  )+reload(sesh list -t --icons)' \
      --bind 'ctrl-g:change-prompt(⚙️  )+reload(sesh list -c --icons)' \
      --bind 'ctrl-x:change-prompt(📁  )+reload(sesh list -z --icons)' \
      --bind 'ctrl-f:change-prompt(🔎  )+reload(fd -H -d 2 -t d -E .Trash . ~)' \
      --bind 'ctrl-d:execute(tmux kill-session -t {2..})+change-prompt(⚡  )+reload(sesh list --icons)' \
      --preview-window 'right:55%' \
      --preview '~/go/bin/sesh preview {}')

  # Use the new variable name in the check
  echo "could connect to: $selected_session"
  if [[ -n "$selected_session" ]]; then
    echo "connecting to: $selected_session"
    # Use the new variable name for the connection
    sesh connect "$selected_session"
  fi
}
zle -N tmux-session-manager
bindkey '^S' tmux-session-manager

#########################################
#########################################
### CTRL-X - command line history search
#########################################
#########################################
fzf-history-widget() {
  # this also matches the height specified by the zoxide widget
  local selected_command=$(fc -l -n -r 1 |
    fzf --height=45% \
        --tiebreak=index \
        --query="$LBUFFER" \
        --bind='ctrl-z:ignore' \
        --border="rounded" --border-label="<  >" --color="label:#caaafe" \
        --prompt='  ')

  # if a command was selected, write that to the buffer
  if [[ -n "$selected_command" ]]; then
    LBUFFER=$selected_command
  fi

  zle redisplay
}
zle     -N   fzf-history-widget
bindkey '^X' fzf-history-widget

###########################################
###########################################
### CTRL-O - clear scrollback
###########################################
###########################################
function clear-scrollback {
  clear
  zle redisplay
}
zle -N clear-scrollback
bindkey '^O' clear-scrollback

###########################################
###########################################
### CTRL-E - open CLI in $EDITOR
###########################################
###########################################
autoload -U edit-command-line
zle -N edit-command-line
bindkey '^E' edit-command-line

###########################################
###########################################
### CTRL-H - keybind help menu
###########################################
###########################################
function keybind-help-menu {
  BUFFER=""
  # zle redisplay
  # echo -ne "\033[1K\r"  # Clears the current line

  echo ""
  echo "\033[1;37m^H · displaying keybinds... ↴\033[0m"

  echo """
  \033[90m[ ]\033[0m\033[90m[1][2][3][4][5]\033[0m
  \033[90m[  ][Q][W]\033[1;35m[E]\033[0m\033[90m[R]\033[0m
  \033[90m[   ]\033[1;31m[A]\033[0m\033[1;32m[S]\033[0m\033[90m[D][F]\033[0m
  \033[90m[↑ ][ ]\033[1;34m[Z]\033[0m\033[1;33m[X]\033[0m\033[90m[C][V]\033[0m
  \033[90m[][ ]\033[1;37m[^]\033[0m\033[90m[  ][]\033[0m

  \033[1;37m^\033[1;35mE\033[0m -> \033[1;35medit buffer in $EDITOR\033[0m
  \033[1;37m^\033[1;31mA\033[0m -> \033[1;31mls (list directories)\033[0m
  \033[1;37m^\033[1;32mS\033[0m -> \033[1;32mwindow file picker\033[0m
  \033[1;37m^\033[1;34mZ\033[0m -> \033[1;34minline file picker\033[0m
  \033[1;37m^\033[1;33mX\033[0m -> \033[1;33mview command history\033[0m
  \033[90m^H -> help menu (this ui)\033[0m
  \033[90m^G -> prepend sudo to the buffer\033[0m
  """

  echo ""
  zle reset-prompt
}
zle -N keybind-help-menu
bindkey '^H' keybind-help-menu