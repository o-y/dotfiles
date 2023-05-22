# Allow zsh to handle '*' like bash
setopt nonomatch

# Cargo
if [ -f "$HOME/.cargo/env" ]; then
    . "$HOME/.cargo/env"
fi
