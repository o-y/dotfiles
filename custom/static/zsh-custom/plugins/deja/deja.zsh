_eval_binary \
    "$commands[deja]" \
    "/opt/homebrew/bin/deja" \
    "~/go/bin/deja" \
    "~/.go/bin/deja" \
    "~/.local/bin/deja" \
    -- init zsh || return 1