# cargo
if [ -e "$HOME/.cargo/env" ]; then
    . "$HOME/.cargo/env"
fi

# go
if [ -e "$HOME/go/bin" ]; then
    export PATH="$PATH:$HOME/go/bin"
fi

# brew
if [ -e "/opt/homebrew/bin/brew" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# conda
if [ -e "$HOME/miniconda3" ]; then
    . "$HOME/miniconda3/etc/profile.d/conda.sh"
fi

# local path
if [ -e "$HOME/.local/bin" ]; then
    export PATH="$PATH:$HOME/.local/bin"
fi

# navi
if type navi &> /dev/null; then
    eval "$(navi widget zsh)"
fi

# brew fpath
if type brew &> /dev/null; then
    fpath+=("/opt/homebrew/share/zsh/site-functions")
fi

# fpath
if [ -e "$HOME/dotfiles/custom/static/fpath" ]; then
    fpath+="$HOME/dotfiles/custom/static/fpath"
fi

# zoxide
if type zoxide &> /dev/null; then
    eval "$(zoxide init zsh --cmd cd)"
fi