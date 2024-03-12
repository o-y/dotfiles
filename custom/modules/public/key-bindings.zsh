#########################################
#########################################
### CTRL-Z - Search for files/directories
#########################################
#########################################

__fsel() {
  local cmd="${FZF_CTRL_T_COMMAND:-"command find -L . -mindepth 1 \\( -path '*/\\.*' -o -fstype 'sysfs' -o -fstype 'devfs' -o -fstype 'devtmpfs' -o -fstype 'proc' \\) -prune \
    -o -type f -print \
    -o -type d -print \
    -o -type l -print 2> /dev/null | cut -b3-"}"
  setopt localoptions pipefail no_aliases 2> /dev/null
  eval "$cmd" | FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} --reverse $FZF_DEFAULT_OPTS $FZF_CTRL_T_OPTS" $(__fzfcmd) -m "$@" | while read item; do
    echo -n "${(q)item} "
  done
  local ret=$?
  echo
  return $ret
}
 
__fzf_use_tmux__() {
  [ -n "$TMUX_PANE" ] && [ "${FZF_TMUX:-0}" != 0 ] && [ ${LINES:-40} -gt 15 ]
}
 
__fzfcmd() {
  __fzf_use_tmux__ &&
    echo "fzf-tmux -d${FZF_TMUX_HEIGHT:-40%}" || echo "fzf"
}
 
fzf-file-widget() {
  LBUFFER="${LBUFFER}$(__fsel)"
  local ret=$?
  zle reset-prompt
  return $ret
}
zle     -N   fzf-file-widget
bindkey '^Z' fzf-file-widget
 
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
### CTRL-S - preprend sudo
###########################################
###########################################
function prepend-sudo {
  if [[ $BUFFER != "sudo "* ]]; then
    BUFFER="sudo $BUFFER"; CURSOR+=5
  fi
}
zle -N prepend-sudo
bindkey '^S' prepend-sudo

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
### CTRL-Y - file picker
###########################################
###########################################
function yazi-filepicker {
  ya < "$TTY"
  zle reset-prompt
}
zle -N yazi-filepicker
bindkey '^Y' yazi-filepicker

###########################################
###########################################
### CTRL-H - keybind help menu
###########################################
###########################################
function keybind-help-menu {
  echo ""
  echo "--~--~--~--"
  echo "ctrl+y - yazi file picker"
  echo "ctrl+e - edit current command in $EDITOR"
  echo "ctrl+s - prepend sudo to the current command"
  echo "ctrl+x - view command history"
  echo "ctrl+z - open in-line file viewer"
  echo "--~--~--~--"
  echo ""
  zle reset-prompt
}
zle -N keybind-help-menu
bindkey '^H' keybind-help-menu

###########################################
###########################################
### CTRL-U - list directories
###########################################
###########################################
function keybind-ls {
  BUFFER=""
  zle redisplay
  echo -ne "\033[1K\r"  # Clears the current line
  
  eza 2>/dev/null || ls
  
  echo ""
  zle reset-prompt
}
zle -N keybind-ls
bindkey '^U' keybind-ls
