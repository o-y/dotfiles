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
    _eval_cache /opt/homebrew/bin/brew shellenv
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
    _eval_cache zoxide init zsh --cmd cd
fi

# mdproxy (google)
if [ -e "$HOME/mdproxy/data/mdproxy_zshrc" ]; then
    source "$HOME/mdproxy/data/mdproxy_zshrc"
fi

# thefuck
if type thefuck &> /dev/null; then
    _eval_cache thefuck --alias
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

# nvm
export NVM_DIR="$HOME/.nvm"
if [[ -d "$NVM_DIR" ]]; then
    _lazy_load_nvm() {
        unfunction node npm npx yarn pnpm nvm 2>/dev/null
        [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
        [[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"
        "$@"
    }
    for cmd in node npm npx yarn pnpm nvm; do
        eval "$cmd() { _lazy_load_nvm $cmd \"\$@\" }"
    done
fi

# atuin
if type atuin &> /dev/null; then
    _eval_cache atuin init zsh --disable-ctrl-r
fi

# mise
if [ -e "$HOME/.local/bin/mise" ]; then
    _eval_cache $HOME/.local/bin/mise activate zsh
fi

# antigravity
if [ -e "$HOME/.antigravity/antigravity/bin" ]; then
    export PATH="$PATH:$HOME/.antigravity/antigravity/bin"
fi

# Radicle
if [ -e "$HOME/.radicle/bin" ]; then
    export PATH="$PATH:$HOME/.radicle/bin"
fi