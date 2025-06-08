##########
### SETUP
##########

__fzf_use_tmux__() {
  [ -n "$TMUX_PANE" ] && [ "${FZF_TMUX:-0}" != 0 ] && [ ${LINES:-40} -gt 15 ]
}
 
__fzfcmd() {
  __fzf_use_tmux__ &&
    echo "fzf-tmux -d${FZF_TMUX_HEIGHT:-40%}" || echo "fzf"
}

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

#########################################
#########################################
### CTRL-X - command line history search
#########################################
#########################################
fzf-history-widget() {
  local selected num
  setopt localoptions noglobsubst noposixbuiltins pipefail no_aliases 2> /dev/null
  selected=( $(fc -rl 1 |
    FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} $FZF_DEFAULT_OPTS -n2..,.. --tiebreak=index --bind=ctrl-r:toggle-sort $FZF_CTRL_R_OPTS --query=${(qqq)LBUFFER} +m" $(__fzfcmd)) )
  local ret=$?
  if [ -n "$selected" ]; then
    num=$selected[1]
    if [ -n "$num" ]; then
      zle vi-fetch-history -n $num
    fi
  fi
  zle reset-prompt
  return $ret
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