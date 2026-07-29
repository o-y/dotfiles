patina_bins=(
    $commands[zsh-patina]
    ~/.cargo/bin/zsh-patina
    /usr/local/bin/zsh-patina
)

for bin in $patina_bins; do
    if [[ -x $bin ]]; then
        eval "$("$bin" activate)"
        return
    fi
done