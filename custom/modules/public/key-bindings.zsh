##########
### SETUP
##########

# Unset TTY control characters inside tmux to allow custom keybindings
# to work. This prevents the terminal driver from intercepting keys
# like Ctrl-Z (suspend) before they reach the zsh line editor.
if [[ -n "$TMUX" ]]; then
  stty stop undef start undef susp undef flush undef  # Free up Ctrl-S/Q/Z/O
fi

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
      --bind 'ctrl-s:change-prompt(  )+reload(sesh list --icons)' \
      --bind 'ctrl-d:execute(tmux kill-session -t {2..})+reload(sesh list --icons)' \
      --preview-window 'right:55%' \
      --preview '~/go/bin/sesh preview {}')

  if [[ -n "$selected_session" ]]; then
    sesh connect "$selected_session"
  fi
  zle redisplay
}
zle -N tmux-session-manager
bindkey '^S' tmux-session-manager

#########################################
#########################################
### CTRL-X - command line history search
#########################################
#########################################
_fzf_history_select_command_from_atuin() {
  local -a fzf_common_opts=("${(@)argv}")
  local selected_command=""

  local colour_purple=$(printf '\033[34m')
  local colour_pink=$(printf '\033[35m')
  local colour_reset=$(printf '\033[0m')
  local atuin_format_string="${colour_purple}{relativetime}${colour_reset} ${colour_pink}{duration}${colour_reset} {command}"

  local selected_output=$(
    atuin history list --reverse --print0 --format "$atuin_format_string" |
      fzf "${fzf_common_opts[@]}" \
          --ansi \
          --tac \
          --read0 \
          --border-label="<  >"
  )

  if [[ -n "$selected_output" ]]; then
    selected_command="${selected_output#* * }"
  fi

  print -r -- "$selected_command"
}

_fzf_history_select_command_from_fc() {
  local -a fzf_common_opts=("${(@)argv}")
  local selected_command=""

  selected_command=$(
    fc -l -n -r 1 | fzf "${fzf_common_opts[@]}" --border-label="<  >"
  )

  print -r -- "$selected_command"
}

fzf-history-widget() {
  local selected_command=""

  local -a fzf_base_opts=(
    --height=45%
    --tiebreak=index
    --query="$LBUFFER"
    --color="label:#caaafe"
    --prompt='  '
  )

  if command -v atuin &>/dev/null; then
    selected_command=$(_fzf_history_select_command_from_atuin "${fzf_base_opts[@]}")
  else
    selected_command=$(_fzf_history_select_command_from_fc "${fzf_base_opts[@]}")
  fi

  if [[ -n "$selected_command" ]]; then
    LBUFFER="${selected_command}"
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
