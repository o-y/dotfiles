##
## tm - tmux Session Manager (Consolidated)
##
function tm() {
  setopt localoptions pipefail

  local usage() {
    echo "[tm] usage: tm <session-name>           attach to session (creates if missing)"
    echo "[tm]"
    echo "[tm] subcommands:"
    echo "[tm]   attach <session-name>            attach to session (creates if missing)"
    echo "[tm]   ls                               list active sessions"
    echo "[tm]   kill <target> | -a, --all        kill session, or kill all sessions"
    echo "[tm]   mv [<target>] <new-name>         rename current or target session"
    echo "[tm]   logs [-f, --follow] <target>     snapshot pane, or stream live output"
    echo "[tm]   reload                           source ~/.tmux.conf"
  }

  (( $+commands[tmux] )) || { echo "[tm] error: tmux not installed." >&2; return 1; }

  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage
    return 0
  fi

  tmux start-server 2>/dev/null

  local cmd=$1
  local err

  case "$cmd" in
    ls)
      tmux list-sessions 2>/dev/null || echo "[tm] no active sessions."
      ;;

    attach)
      local target=${2:-default}
      if [[ -n "$TMUX" ]]; then
        tmux has-session -t "$target" 2>/dev/null || tmux new-session -d -s "$target"
        err=$(tmux switch-client -t "$target" 2>&1) || { echo "[tm] error: ${err:l}" >&2; return 1; }
      else
        err=$(tmux new-session -A -s "$target" 2>&1) || { echo "[tm] error: ${err:l}" >&2; return 1; }
      fi
      ;;

    kill)
      local target=$2
      if [[ "$target" == "-a" || "$target" == "--all" ]]; then
        err=$(tmux kill-server 2>&1) || { echo "[tm] error: no active sessions." >&2; return 1; }
        echo "[tm] deleted: all sessions"
      elif [[ -n "$target" ]]; then
        err=$(tmux kill-session -t "$target" 2>&1) || { echo "[tm] error: ${err:l}" >&2; return 1; }
        echo "[tm] deleted: session '$target'"
      else
        echo "[tm] usage: tm kill <target> | -a" >&2; return 1
      fi
      ;;

    mv)
      if [[ $# -eq 3 ]]; then
        err=$(tmux rename-session -t "$2" "$3" 2>&1) || { echo "[tm] error: ${err:l}" >&2; return 1; }
        echo "[tm] renamed: '$2' -> '$3'"
      elif [[ $# -eq 2 ]]; then
        [[ -z "$TMUX" ]] && { echo "[tm] error: must be inside tmux to rename implicitly." >&2; return 1; }
        err=$(tmux rename-session "$2" 2>&1) || { echo "[tm] error: ${err:l}" >&2; return 1; }
        echo "[tm] renamed: current -> '$2'"
      else
        echo "[tm] usage: tm mv [<target>] <new-name>" >&2; return 1
      fi
      ;;

    logs)
      local follow=0 target=$2
      if [[ "$target" == "-f" || "$target" == "--follow" ]]; then
        follow=1; target=$3
      fi
      [[ -z "$target" ]] && { echo "[tm] usage: tm logs [-f] <target>" >&2; return 1; }
      tmux has-session -t "$target" 2>/dev/null || { echo "[tm] error: session '$target' not found." >&2; return 1; }

      if (( follow )); then
        local log_file=$(mktemp /tmp/tm-tail-XXXXXX.log)
        err=$(tmux pipe-pane -t "${target}:" "cat >> $log_file" 2>&1) || { echo "[tm] error: ${err:l}" >&2; rm -f "$log_file"; return 1; }
        trap "tmux pipe-pane -t '${target}:' 2>/dev/null; rm -f '$log_file'; trap - INT; return" INT
        echo "[tm] tailing active pane of '$target' (ctrl+c to stop)..."
        tail -f "$log_file"
        tmux pipe-pane -t "${target}:" 2>/dev/null
        rm -f "$log_file"
        trap - INT
      else
        local term_width=${COLUMNS:-$(tput cols 2>/dev/null || printf 80)}
        local border=$(printf '%*s' $((term_width - 5)) '' | tr ' ' '─')
        echo "[tm] $border"
        tmux capture-pane -pe -t "${target}:" 2>/dev/null | awk '
          BEGIN { blank = "" }
          {
            sub(/\r$/, ""); clean = $0; gsub(/\x1B\[[0-9;]*[a-zA-Z]/, "", clean)
            if (clean ~ /^[ \t]*$/) { blank = blank $0 "\033[0m\n" }
            else { if (blank != "") { printf "%s", blank; blank = "" }; print $0 "\033[0m" }
          }' || { echo "[tm] error: failed to capture '$target'." >&2; return 1; }
        echo "[tm] $border"
      fi
      ;;

    reload)
      err=$(tmux source-file ~/.tmux.conf 2>&1) || { echo "[tm] error: ${err:l}" >&2; return 1; }
      echo "[tm] reloaded: ~/.tmux.conf"
      ;;

    *)
      # Implicit Attach / Create Fallback
      local target=${cmd:-default}
      if [[ -n "$TMUX" ]]; then
        tmux has-session -t "$target" 2>/dev/null || tmux new-session -d -s "$target"
        err=$(tmux switch-client -t "$target" 2>&1) || { echo "[tm] error: ${err:l}" >&2; return 1; }
      else
        err=$(tmux new-session -A -s "$target" 2>&1) || { echo "[tm] error: ${err:l}" >&2; return 1; }
      fi
      ;;
  esac
}

##
## tm compdef
##
function _tm() {
  local -a sessions subcommands

  sessions=(${(f)"$(tmux list-sessions -F '#S' 2>/dev/null)"})

  subcommands=(
    'attach:attach to session (creates if missing)'
    'ls:list active sessions'
    'kill:kill session(s)'
    'mv:rename a session'
    'logs:snapshot or stream active pane'
    'reload:reload tmux config'
  )

  _arguments -C \
    '1: :->cmd_or_sess' \
    '*:: :->args'

  case $state in
    cmd_or_sess)
      _describe 'subcommand' subcommands
      if (( ${#sessions[@]} > 0 )); then
        local expl
        _wanted sessions expl 'attach/create' compadd -a sessions
      fi
      ;;
    args)
      case $line[1] in
        attach)
          if (( CURRENT == 2 )); then
            local expl
            _wanted sessions expl 'session name' compadd -a sessions
          fi
          ;;
        kill)
          if (( CURRENT == 2 )); then
            local expl
            _wanted sessions expl 'session name' compadd -a sessions
            local -a kill_opts=('-a:kill all sessions' '--all:kill all sessions')
            _describe 'options' kill_opts
          fi
          ;;
        mv)
          if (( CURRENT == 2 )); then
            local expl
            _wanted sessions expl 'session name' compadd -a sessions
          fi
          ;;
        logs)
          if (( CURRENT == 2 )); then
            local expl
            _wanted sessions expl 'session name' compadd -a sessions
            local -a log_opts=('-f:stream live output' '--follow:stream live output')
            _describe 'options' log_opts
          elif (( CURRENT == 3 )) && [[ ${line[2]} == -* ]]; then
            local expl
            _wanted sessions expl 'session name' compadd -a sessions
          fi
          ;;
      esac
      ;;
  esac
}

compdef _tm tm