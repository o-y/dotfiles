function parse_git_branch() {
    local branch=$(git branch 2> /dev/null | sed -n -e 's/^\* \(.*\)/\1/p')
    [[ -n "$branch" ]] && echo " [$branch]" || echo ""
}

function parse_python_virtual_env() {
    local env_name=$(
        [[ -n "$VIRTUAL_ENV" ]] && echo "$(basename "$VIRTUAL_ENV")" || 
        [[ -n "$CONDA_DEFAULT_ENV" ]] && echo "$CONDA_DEFAULT_ENV"
    )

    [[ -n "$env_name" ]] && echo " [py:$env_name]"
}

COLOR_USR=$'\e[38;5;255m'
COLOR_AT=$'\e[38;5;250m'
COLOR_DIR=$'\e[38;5;38m'
COLOR_GIT=$'\e[38;5;219m'
COLOR_PY=$'\e[38;5;250m'

NEWLINE=$'\n'
COLOR_DEF=$'\e[38;5;250m'

precmd() {
    # FIRST LINE
    PROMPT='%B'                                # start of bold sequence
    PROMPT+="${COLOR_USR}%n"                   # display username
    PROMPT+="${COLOR_AT}@"                     # display @ symbol
    PROMPT+="${COLOR_USR}%m"                   # display hostname
    PROMPT+=" ${COLOR_DIR}%~"                  # display current directory
    PROMPT+="${COLOR_GIT}$(parse_git_branch)"  # display git branch
    PROMPT+="${COLOR_PY}$(parse_python_virtual_env)" # display python virtual env

    # SECOND LINE
    PROMPT+="${COLOR_DEF}${NEWLINE}"           # reset color and add newline
    PROMPT+='~%b '                             # display tilde

    export PROMPT
}

# unlike precmd, chpwd is ran after a command is executed, therefore
# it needs to be called once when we start a new session
# however this doesn't play well with widgets which change the current
# directory, thus the need to use chpwd as well
# TODO: consolidate this into a single function, this is fucked.
chpwd() {
    precmd
}

chpwd