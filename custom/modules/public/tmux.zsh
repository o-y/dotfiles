##
## tm - tmux Session Manager
##
function tm() {
  setopt localoptions pipefail

  local usage() {
    echo "[tm] tm - tmux session manager"
    echo "[tm] usage: tm <command> [args...]"
    echo "[tm]"
    echo "[tm] commands:"
    echo "[tm]   ls          list all running tmux sessions"
    echo "[tm]   attach      attach to a running session"
    echo "[tm]   new         create and attach to a new session"
    echo "[tm]   delete      delete (kill) a session"
    echo "[tm]   delete-all  delete (kill) all sessions"
    echo "[tm]   rename      rename a session (1 arg: current, 2 args: target new-name)"
    echo "[tm]   spy         print a colored snapshot of the active pane"
    echo "[tm]   tail        stream live output of the active pane"
    echo "[tm]   reload      source ~/.tmux.conf"
  }

  (( $+commands[tmux] )) || { echo "[tm] error: tmux is not installed." >&2; return 1; }

  if [[ $# -eq 0 || "$1" == "-h" || "$1" == "--help" ]]; then
    usage
    [[ $# -eq 0 ]] && return 1 || return 0
  fi

  tmux start-server

  local cmd=$1
  local err

  case "$cmd" in
    ls)
      tmux list-sessions 2>/dev/null || echo "[tm] no active sessions."
      ;;

    attach|delete|spy|tail)
      local target=$2
      [[ -z "$target" ]] && { echo "[tm] usage: tm $cmd <target>" >&2; return 1; }
      tmux has-session -t "$target" 2>/dev/null || { echo "[tm] error: session '$target' not found." >&2; return 1; }
      
      case "$cmd" in
        attach)
          if [[ -n "$TMUX" ]]; then
            err=$(tmux switch-client -t "$target" 2>&1) || { echo "[tm] error: ${err:l}" >&2; return 1; }
          else
            err=$(tmux attach-session -t "$target" 2>&1) || { echo "[tm] error: ${err:l}" >&2; return 1; }
          fi
          ;;
        
        delete)
          err=$(tmux kill-session -t "$target" 2>&1) || { echo "[tm] error: ${err:l}" >&2; return 1; }
          echo "[tm] deleted: session '$target'"
          ;;
        
        spy)
          local term_width=${COLUMNS:-$(tput cols 2>/dev/null || printf 80)}
          local border_width=$((term_width - 5)) # Account for the "[tm] " prefix
          local border=$(printf '%*s' "$border_width" '' | tr ' ' '─')
          
          echo "[tm] $border"
          
          tmux capture-pane -pe -t "${target}:" 2>/dev/null | awk '
            BEGIN { blank_buffer = "" }
            {
              sub(/\r$/, "")
              clean = $0
              gsub(/\x1B\[[0-9;]*[a-zA-Z]/, "", clean)
              
              if (clean ~ /^[ \t]*$/) {
                blank_buffer = blank_buffer $0 "\033[0m\n"
              } else {
                if (blank_buffer != "") {
                  printf "%s", blank_buffer
                  blank_buffer = ""
                }
                print $0 "\033[0m"
              }
            }
          '
          
          if [[ $? -ne 0 ]]; then
            echo "[tm] error: failed to capture pane data for '$target'." >&2
            return 1
          fi
          
          echo "[tm] $border"
          ;;
        
        tail)
          local log_file=$(mktemp /tmp/tm-tail-XXXXXX.log)
          err=$(tmux pipe-pane -t "${target}:" "cat >> $log_file" 2>&1) || { echo "[tm] error: ${err:l}" >&2; rm -f "$log_file"; return 1; }
          
          trap "tmux pipe-pane -t '${target}:' 2>/dev/null; rm -f '$log_file'; trap - INT; return" INT
          
          echo "[tm] tailing active pane of '$target' (ctrl+c to stop)..."
          tail -f "$log_file"
          
          tmux pipe-pane -t "${target}:" 2>/dev/null
          rm -f "$log_file"
          trap - INT
          ;;
      esac
      ;;

    new)
      local target=$2
      [[ -z "$target" ]] && { echo "[tm] usage: tm new <target>" >&2; return 1; }
      tmux has-session -t "$target" 2>/dev/null && { echo "[tm] error: session '$target' already exists." >&2; return 1; }
      
      if [[ -n "$TMUX" ]]; then
        err=$(tmux new-session -d -s "$target" 2>&1) || { echo "[tm] error: ${err:l}" >&2; return 1; }
        err=$(tmux switch-client -t "$target" 2>&1) || { echo "[tm] error: ${err:l}" >&2; return 1; }
      else
        err=$(tmux new-session -s "$target" 2>&1) || { echo "[tm] error: ${err:l}" >&2; return 1; }
      fi
      ;;

    delete-all)
      err=$(tmux kill-server 2>&1) || { echo "[tm] error: no active sessions to delete." >&2; return 1; }
      echo "[tm] deleted: all sessions"
      ;;

    rename)
      if [[ $# -eq 3 ]]; then
        local src=$2
        local dst=$3
        tmux has-session -t "$src" 2>/dev/null || { echo "[tm] error: session '$src' not found." >&2; return 1; }
        
        err=$(tmux rename-session -t "$src" "$dst" 2>&1) || { echo "[tm] error: ${err:l}" >&2; return 1; }
        echo "[tm] renamed: session '$src' to '$dst'"
      
      elif [[ $# -eq 2 ]]; then
        local new_name=$2
        if [[ -z "$TMUX" ]]; then
          echo "[tm] error: must be inside a tmux session to rename without a target." >&2
          echo "[tm] usage: tm rename <target> <new-name>" >&2
          return 1
        fi
        
        err=$(tmux rename-session "$new_name" 2>&1) || { echo "[tm] error: ${err:l}" >&2; return 1; }
        echo "[tm] renamed: current session to '$new_name'"
      
      else
        echo "[tm] usage: tm rename [<target>] <new-name>" >&2
        return 1
      fi
      ;;

    reload)
      err=$(tmux source-file ~/.tmux.conf 2>&1) || { echo "[tm] error: ${err:l}" >&2; return 1; }
      echo "[tm] reloaded: ~/.tmux.conf"
      ;;

    *)
      echo "[tm] error: unknown command '$cmd'"
      echo "[tm]"
      usage
      return 1
      ;;
  esac
}

##
## tm compdef
##
function _tm() {
  local -a subcommands=(
    'ls:list running sessions'
    'attach:attach to a running session'
    'new:create a new session'
    'delete:delete (kill) a session'
    'delete-all:delete (kill) ALL sessions'
    'rename:rename a session'
    'spy:print a colored snapshot of the active pane'
    'tail:stream live output of the active pane'
    'reload:reload tmux configuration'
  )

  _arguments \
    '1: :_values "subcommand" ${subcommands[@]}' \
    '2: :->arg2' \
    '3: :->arg3'

  case $state in
    arg2)
      local -a sessions=(${(f)"$(tmux list-sessions -F '#S' 2>/dev/null)"})

      case $words[2] in
        attach|delete|spy|tail)
          if (( ${#sessions[@]} > 0 )) && [[ -n "${sessions[1]}" ]]; then
            _describe 'session' sessions
          else
            _message "no active sessions"
          fi
          ;;
        new)
          _message "enter session name"
          ;;
        rename)
          if [[ -n "$TMUX" ]]; then
            _message "new name for current session OR target session to rename"
          else
            _message "target session to rename (requires 2 args)"
          fi
          
          if (( ${#sessions[@]} > 0 )) && [[ -n "${sessions[1]}" ]]; then
            _describe 'session' sessions
          fi
          ;;
      esac
      ;;
      
    arg3)
      case $words[2] in
        rename)
          _message "enter new session name"
          ;;
      esac
      ;;
  esac
}

compdef _tm tm