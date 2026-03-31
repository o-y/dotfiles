alias py=python3
alias pip=pip3
alias f=fuck
alias c=clear

# clean
alias hoover="ps -u $(whoami) -o pid,comm | grep -E '/Applications/|/Users/' | grep -vE 'Google Chrome|Ghostty|Terminal' | awk '{print \$1}' | xargs kill -9 2>/dev/null"
alias dry-hoover="ps -u $(whoami) -o pid,comm | grep -E '/Applications/|/Users/' | grep -vE 'Google Chrome|Ghostty|Terminal' | awk '{print \$1}' | xargs ps -p"

# profile
alias zsh_profile="ZSH_PROFILE=1 zsh -i -c exit"
alias zsh_bench="hyperfine --runs 150 --warmup 40 'zsh -i -c exit'"

# cd util
mkcd () { mkdir "$@" && cd "$@"; }

# edit
function edit() {
    local editor
    (( $+commands[fresh] )) && editor="fresh" || editor="nano"

    if [[ ! -t 0 ]]; then
        local tmpfile=$(mktemp "${TMPDIR:-/tmp}/edit.XXXXXX")
        cat > "$tmpfile"
        $editor "$tmpfile" < /dev/tty > /dev/tty
        rm -f "$tmpfile"
    else
        $editor "$@"
    fi
}