# --- PATH setup ---
[[ -d "$HOME/.cargo/bin" ]]    && path+=("$HOME/.cargo/bin")
[[ -d "$HOME/go/bin" ]]        && path+=("$HOME/go/bin")
[[ -d "$HOME/.local/bin" ]]    && path+=("$HOME/.local/bin")
[[ -d "$HOME/.bun/bin" ]]      && path+=("$HOME/.bun/bin")
[[ -d "$HOME/.pixi/bin" ]]     && path+=("$HOME/.pixi/bin")
[[ -d "$HOME/.radicle/bin" ]]  && path+=("$HOME/.radicle/bin")
[[ -d "/opt/homebrew/bin" ]]   && path+=("/opt/homebrew/bin")
[[ -d "/usr/local/bin" ]]      && path+=("/usr/local/bin")
[[ -d "$HOME/.antigravity/antigravity/bin" ]] && path+=("$HOME/.antigravity/antigravity/bin")
[[ -d "/Applications/Visual Studio Code.app/Contents/Resources/app/bin" ]] && path+=("/Applications/Visual Studio Code.app/Contents/Resources/app/bin")

# mac brew (cached)
[[ -x "/opt/homebrew/bin/brew" ]] && _eval_cache /opt/homebrew/bin/brew shellenv

# fpath setup
(( $+commands[brew] )) && fpath+=("/opt/homebrew/share/zsh/site-functions")
[[ -d "$HOME/dotfiles/custom/static/fpath" ]] && fpath+=("$HOME/dotfiles/custom/static/fpath")
[[ -d "${ZSH_CUSTOM:-__none__}/plugins/zsh-completions/src" ]] && fpath+=("$ZSH_CUSTOM/plugins/zsh-completions/src")

# zoxide (cached)
(( $+commands[zoxide] )) && _eval_cache zoxide init zsh --cmd cd

# thefuck (cached)
(( $+commands[thefuck] )) && _eval_cache thefuck --alias

# pixi completions (cached)
(( $+commands[pixi] )) && _eval_cache pixi completion --shell zsh

# bun completions (cached)
[[ -f "$HOME/.bun/_bun" ]] && _eval_cache source "$HOME/.bun/_bun"

# jj completions (cached)
(( $+commands[jj] )) && _eval_cache COMPLETE=zsh jj

# direnv (cached)
(( $+commands[direnv] )) && _eval_cache direnv hook zsh

# atuin (cached)
(( $+commands[atuin] )) && _eval_cache atuin init zsh --disable-ctrl-r --disable-up-arrow

# mise (cached)
[[ -x "$HOME/.local/bin/mise" ]] && _eval_cache $HOME/.local/bin/mise activate zsh

# nvm (lazy-loaded)
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

