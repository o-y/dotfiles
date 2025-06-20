##########
### SETUP
##########

_apply_keybinds() {
  # echo "custom: $0"

  # Unset TTY control characters inside tmux to allow custom keybindings
  # to work. This prevents the terminal driver from intercepting keys
  # like Ctrl-Z (suspend) before they reach the zsh line editor (ZLE).
  if [[ -n "$TMUX" ]]; then
    stty stop undef
    stty start undef
    stty susp undef
    stty flush undef
  fi

  # Register widgets and bind keys
  zle -N zoxide-filepicker
  bindkey '^Z' zoxide-filepicker

  zle -N fzf-history-widget
  bindkey '^X' fzf-history-widget

  zle -N clear-scrollback
  bindkey '^O' clear-scrollback

  zle -N edit-command-line
  bindkey '^E' edit-command-line
}

autoload -Uz add-zsh-hook

_apply_keybinds "test"
zle_line_init_hook+=(_apply_keybinds)