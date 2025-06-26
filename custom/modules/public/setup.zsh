# cargo
if [ -e "$HOME/.cargo/env" ]; then
    . "$HOME/.cargo/env"
fi

# go
if [ -e "$HOME/go/bin" ]; then
    export PATH="$PATH:$HOME/go/bin"
fi

# local path
if [ -e "$HOME/.local/bin" ]; then
    export PATH="$PATH:$HOME/.local/bin"
fi

# mac brew
if [ -e "/opt/homebrew/bin/brew" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# brew fpath
if type brew &> /dev/null; then
    fpath+=("/opt/homebrew/share/zsh/site-functions")
fi

# linux brew
if [ -e "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
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

# thefuck
if type thefuck &> /dev/null; then
    eval $(thefuck --alias)
fi

# bun
if [ -e "$HOME/.bun/_bun" ]; then
    source "$HOME/.bun/_bun"
    export PATH="$PATH:$HOME/.bun/bin"
fi

# jj
if type jj &> /dev/null; then
    source <(COMPLETE=zsh jj)
fi

# vscode (code binary)
if [ -e "/Applications/Visual Studio Code.app/Contents/Resources/app/bin" ]; then
    export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
fi

# pyenv
if ! type pyenv &> /dev/null; then
    if [ -e "$HOME/.pyenv/bin" ]; then
        export PYENV_ROOT="$HOME/.pyenv"
        export PATH="$PYENV_ROOT/bin:$PATH"
        eval "$(pyenv init - zsh)"
    fi
fi

# nvm
if [ -e "$HOME/.nvm" ]; then
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
fi

# atuin
if type atuin &> /dev/null; then
    eval "$(atuin init zsh --disable-up-arrow --disable-ctrl-r)"
fi