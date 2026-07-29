if [[ -z "${commands[iris]}" ]]; then
    return
fi

# Iris Autostart Hook
if [ -n "$TMUX" ] && [ -n "$IRIS_PID" ]; then
    if ps -o comm= -p $PPID 2>/dev/null | grep -q "tmux"; then
        unset IRIS_PID IRIS_IS_CHILD IRIS_FD
    fi
fi

if [ -z "$IRIS_PID" ] && [ -z "$IRIS_RESCUE" ]; then
    export IRIS_ACTIVE_SHELL="zsh"
    exec iris
fi

# Iris Autocomplete Hook
if [ -n "$IRIS_PID" ] && [ -n "$IRIS_FD" ]; then
  _iris_send_lbuffer() {
    print -u $IRIS_FD -N -r -- "$LBUFFER" 2>/dev/null
  }

  _iris_precmd() {
    print -u $IRIS_FD -N -r -- "IRIS_CMD_STOP" 2>/dev/null
  }

  _iris_preexec() {
    print -u $IRIS_FD -N -r -- "IRIS_CMD_START" 2>/dev/null
  }

  autoload -Uz add-zle-hook-widget
  autoload -Uz add-zsh-hook

  add-zle-hook-widget line-pre-redraw _iris_send_lbuffer
  add-zsh-hook precmd _iris_precmd
  add-zsh-hook preexec _iris_preexec
fi