# cargo
if [ -e "$HOME/.cargo/env" ]; then
    . "$HOME/.cargo/env"
fi

# go
if [ -e "$HOME/go/bin" ]; then
    export PATH="$PATH:$HOME/go/bin"
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

# brew
if [ -e "/opt/homebrew/bin/brew" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# brew fpath
if type brew &> /dev/null; then
    fpath+=("/opt/homebrew/share/zsh/site-functions")
fi

# fpath
if [ -e "$HOME/dotfiles/custom/static/fpath" ]; then
    fpath+="$HOME/dotfiles/custom/static/fpath"
fi

# zsh-completions fpath
if [ -e "$ZSH_CUSTOM/plugins/zsh-completions/src" ]; then
    fpath+="$ZSH_CUSTOM/plugins/zsh-completions/src"
fi

# zoxide
if type zoxide &> /dev/null; then
    eval "$(zoxide init zsh --cmd cd)"
fi

# mdproxy (google)
if [ -e "$HOME/mdproxy/data/mdproxy_zshrc" ]; then
  source "$HOME/mdproxy/data/mdproxy_zshrc"
fi
