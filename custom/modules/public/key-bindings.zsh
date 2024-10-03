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
  zle redisplay

  cdfile=$(mktemp)
  xplr --print-pwd-as-result < "$TTY" > $cdfile
  if [[ -s "$cdfile" ]]; then
    cd "$(cat $cdfile)"

    # echo -ne "\033[1K\r"  # Clears the current line
    echo ""
    eza -l -h --git --icons --no-filesize 2>/dev/null || ls
    echo ""
  fi

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
  echo "ctrl+x - view command history"
  echo "ctrl+y - file picker"
  echo "ctrl+z - inline file picker"
  echo "ctrl+e - edit buffer in $EDITOR"
  echo "ctrl+s - prepend sudo to the buffer"
  echo "ctrl+g - open navi cheat sheet"
  echo "ctrl+u - ls"
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
  
  eza -l -h --git --icons --no-filesize 2>/dev/null || ls
  
  echo ""
  zle reset-prompt
}
zle -N keybind-ls
bindkey '^U' keybind-ls
