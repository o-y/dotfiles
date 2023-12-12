# allow zsh to handle '*' like bash
setopt nonomatch

# cargo
if [ -f "$HOME/.cargo/env" ]; then
    . "$HOME/.cargo/env"
fi

# brew
if [ -f "/opt/homebrew/bin/brew" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# conda
if [ -f "$HOME/miniconda3" ]; then
    . "$HOME/miniconda3/etc/profile.d/conda.sh"
fi