alias py=python3
alias pip=pip3
alias f=fuck
alias c=clear

# suffix alias
alias -s json="fx"
alias -s md="cat"

# clean
alias hoover="ps -u $(whoami) -o pid,comm | grep -E '/Applications/|/Users/' | grep -vE 'Google Chrome|Ghostty|Terminal' | awk '{print \$1}' | xargs kill -9 2>/dev/null"
alias dry-hoover="ps -u $(whoami) -o pid,comm | grep -E '/Applications/|/Users/' | grep -vE 'Google Chrome|Ghostty|Terminal' | awk '{print \$1}' | xargs ps -p"

# profile
alias zsh_profile="ZSH_PROFILE=1 zsh -i -c exit"
alias zsh_bench="hyperfine --runs 1000 --warmup 400 'zsh -i -c exit'"