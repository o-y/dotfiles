_eval_binary \
    --no-eval-cache \
    "$commands[zsh-patina]" \
    "/usr/local/bin/zsh-patina" \
    "$HOME/.cargo/bin/zsh-patina" \
    -- activate || return 1