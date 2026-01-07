function tm() {
  # Ensure tmux is installed before proceeding.
  if ! command -v tmux &> /dev/null; then
    echo "Error: tmux is not installed. Please install it to use 'tm'." >&2
    return 1
  fi

  # Show usage if no arguments are provided.
  if [[ $# -eq 0 ]]; then
    echo "Usage: tm <command> [session-name]"
    echo ""
    echo "commands:"
    echo "  ls                List all running tmux sessions"
    echo "  attach <name>     Attach to a running session"
    echo "  new <name>        Create and attach to a new session"
    echo "  delete <name>     Delete (kill) a session"
    return 1
  fi

  local subcommand=$1
  local session_name=$2

  case "$subcommand" in
    ls)
      # Use tmux's built-in 'ls' command. It's informative and handles the
      # "no server" case gracefully.
      tmux list-sessions
      ;;

    attach)
      if [[ -z "$session_name" ]]; then
        echo "Error: Missing session name for 'attach'." >&2
        echo "Usage: tm attach <session-name>" >&2
        return 1
      fi

      # Check if the session exists before trying to attach.
      if ! tmux has-session -t "$session_name" 2>/dev/null; then
        echo "Error: Session '$session_name' not found." >&2
        return 1
      fi

      # If already inside tmux, switch to the target session.
      # Otherwise, attach to it from the main shell.
      if [[ -n "$TMUX" ]]; then
        tmux switch-client -t "$session_name"
      else
        tmux attach-session -t "$session_name"
      fi
      ;;

    new)
      if [[ -z "$session_name" ]]; then
        echo "Error: Missing session name for 'new'." >&2
        echo "Usage: tm new <session-name>" >&2
        return 1
      fi

      # Don't create if a session with that name already exists.
      if tmux has-session -t "$session_name" 2>/dev/null; then
        echo "Error: Session '$session_name' already exists. Attach with 'tm attach $session_name'." >&2
        return 1
      fi
      
      # If inside tmux, create the new session in the background (-d) and then switch to it.
      # This avoids nesting sessions.
      if [[ -n "$TMUX" ]]; then
        tmux new-session -d -s "$session_name"
        tmux switch-client -t "$session_name"
      else
        # If not in tmux, create and attach directly.
        tmux new-session -s "$session_name"
      fi
      ;;

    delete)
      if [[ -z "$session_name" ]]; then
        echo "Error: Missing session name for 'delete'." >&2
        echo "Usage: tm delete <session-name>" >&2
        return 1
      fi

      # Check if the session exists before trying to delete.
      if ! tmux has-session -t "$session_name" 2>/dev/null; then
        echo "Error: Session '$session_name' not found." >&2
        return 1
      fi

      tmux kill-session -t "$session_name" && echo "Session '$session_name' deleted."
      ;;

    *)
      echo "Error: Unknown command '$subcommand'." >&2
      echo "Run 'tm' for usage information." >&2
      return 1
      ;;
  esac
}

# Zsh completion function for the 'tm' command.
function _tm() {
  local -a subcommands
  subcommands=(
    'ls:List running sessions'
    'attach:Attach to a running session'
    'new:Create a new session'
    'delete:Delete (kill) a session'
  )

  # This state machine tells zsh what to complete and when.
  _arguments \
    '1: :_values "subcommand" ${subcommands[@]}' \
    '2: :->session_name_completion'

  case $state in
    session_name_completion)
      # Get a list of current tmux session names.
      # The `(f)` flag splits the command output on newlines.
      # `2>/dev/null` suppresses errors if the tmux server isn't running.
      local -a sessions
      sessions=(${(f)"$(tmux list-sessions -F '#S' 2>/dev/null)"})

      case $words[2] in
        # For 'attach' and 'delete', we should only complete existing sessions.
        attach|delete)
          _describe 'session' sessions
          ;;
        # For 'new', there are no predefined completions.
        new)
          _message "enter new session name"
          ;;
      esac
      ;;
  esac
}

# Register the completion function for the 'tm' command.
compdef _tm tm