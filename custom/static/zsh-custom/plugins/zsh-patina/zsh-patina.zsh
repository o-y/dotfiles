_patina_bin() {
    local -a candidates=(zsh-patina ~/.cargo/bin/zsh-patina /usr/local/bin/zsh-patina)
    local p=(${^candidates}(x[1]N))
    [[ -n $p ]] && { echo $p; return }
    echo "[error] zsh-patina binary not found in any known location" >&2
    return 1
}

eval "$($(_patina_bin) activate)"