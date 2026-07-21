##########
### SETUP
##########

# Unset TTY control characters inside tmux to allow custom keybindings
# to work. This prevents the terminal driver from intercepting keys
# like Ctrl-Z (suspend) before they reach the zsh line editor.

# TODO work out whether this should be conditioned...
# if [[ -n "$TMUX" ]]; then
stty stop undef start undef susp undef flush undef  # Free up Ctrl-S/Q/Z/O
# fi

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

###########################################
###########################################
### UP/DOWN ARROWS - open Atuin history
###########################################
###########################################
_atuin_search_with_clear() {
  # Fix: clear zsh-autosuggestions ghost text 
  #      before Atuin replaces the buffer.
  zle autosuggest-clear 2>/dev/null || true
  zle _atuin_search_widget
}
zle -N _atuin_search_with_clear
bindkey '^[[A' _atuin_search_with_clear  # Up arrow
bindkey '^[OA' _atuin_search_with_clear  # Up arrow (alternate terminfo)














#######

zmodload zsh/parameter

typeset -ga __prev_suspended_jobs
export __TRACKED_JOB_RUNNING=0

_task_lifecycle_precmd() {
  local exit_code=$? # Capture exit code immediately 
  
  # ---------------------------------------------------------
  # PHASE 1: Detect Completion of a Tracked Task
  # ---------------------------------------------------------
  if [[ "$__TRACKED_JOB_RUNNING" == "1" ]]; then
    __TRACKED_JOB_RUNNING=0
    local current_pane=$(tmux display-message -p '#D')
    local tui_pane=$(tmux show-option -p -t "$current_pane" -q -v @linked_tui_pane)
    local my_window=$(tmux display-message -p '#W')
    
    # 1. If we are currently hidden in the background window, we must 
    # swap ourselves back to the active window before drawing the result.
    if [[ "$my_window" == "bg-tasks" && -n "$tui_pane" ]]; then
      tmux swap-pane -s "$current_pane" -t "$tui_pane"
    fi
    
    # 2. Destroy the TUI proxy pane (it's no longer needed)
    if [[ -n "$tui_pane" ]]; then
      tmux kill-pane -t "$tui_pane" 2>/dev/null
    fi
    
    # 3. Resize ourselves to 35% to diagnose the output
    tmux resize-pane -y 35
    
    # 4. Print the borderless banner
    if [[ $exit_code -eq 0 ]]; then
      print -P "\n  %F{green}%B[ ✔ SUCCESS ]%b %F{240}Task completed.%f\n"
    else
      print -P "\n  %F{red}%B[ ✘ FAILURE ]%b %F{240}Task exited with code $exit_code.%f\n"
    fi
    
    # Cleanup Tmux memory
    tmux set-option -p -t "$current_pane" -u @linked_tui_pane
    __prev_suspended_jobs=(${(k)jobstates[(R)suspended:*]})
    return
  fi

  # ---------------------------------------------------------
  # PHASE 2: Detect New Suspensions
  # ---------------------------------------------------------
  local -a current_suspended_jobs
  current_suspended_jobs=(${(k)jobstates[(R)suspended:*]})
  
  local -a newly_suspended
  newly_suspended=(${current_suspended_jobs:|__prev_suspended_jobs})
  
  if (( ${#newly_suspended} > 0 )); then
    for job_id in $newly_suspended; do
      local process_cmd=${jobtexts[$job_id]}
      
      if [[ -n "$TMUX" ]]; then
        local current_pane=$(tmux display-message -p '#D')
        
        # 1. Create the new 90% top pane (your fresh prompt)
        tmux split-window -v -b -p 90 -c "$PWD"
        local top_pane=$(tmux display-message -p '#D')
        
        # 2. Break the suspended job to a hidden background window
        tmux break-pane -d -s "$current_pane" -n "bg-tasks"
        
        # 3. Create the 10% TUI pane where the job used to be.
        # We pass the command name via environment variable (-e) to avoid quoting hell,
        # and execute an infinite zsh loop that draws the UI.
        tmux split-window -t "$top_pane" -v -p 10 -e "TUI_CMD=$process_cmd" -c "$PWD" zsh -c '
          print -n "\e[?25l" # Hide cursor
          trap "print -n \"\e[?25h\"" EXIT
          clear
          print -P "\n  %F{yellow}⏳ RUNNING:%f %B${TUI_CMD}%b"
          print -P "  %F{240}Press Ctrl+Space to toggle output%f"
          while true; do sleep 1000; done
        '
        local tui_pane=$(tmux display-message -p '#D')
        
        # 4. Link the two panes together via custom Tmux options
        tmux set-option -p -t "$current_pane" @linked_tui_pane "$tui_pane"
        tmux set-option -p -t "$tui_pane" @linked_job_pane "$current_pane"
        
        # 5. Mark the job pane state and resume it in the background
        __TRACKED_JOB_RUNNING=1
        tmux send-keys -t "$current_pane" "fg %$job_id" Enter
      fi
    done
  fi
  
  __prev_suspended_jobs=($current_suspended_jobs)
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd _task_lifecycle_precmd