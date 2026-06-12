setopt PROMPT_SUBST

# Colours
COLOUR_USR=$'%{\e[38;5;255m%}'
COLOUR_AT=$'%{\e[38;5;250m%}'
COLOUR_DIR=$'%{\e[38;5;38m%}'
COLOUR_GIT=$'%{\e[38;5;219m%}'
COLOUR_PY=$'%{\e[38;5;250m%}'
COLOUR_DIR_ENV=$'%{\e[38;5;250m%}'
COLOUR_DEF=$'%{\e[38;5;250m%}'
NEWLINE=$'\n'

# Defaults
typeset -g __PROMPT_GIT=""
typeset -g __PROMPT_PY=""
typeset -g __PROMPT_DIRENV=""

function _update_prompt_info() {
    # ============================
    # Parse Git
    # ============================
    local git_branch
    git_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [[ -n "$git_branch" ]]; then
        __PROMPT_GIT=" [$git_branch]"
    else
        __PROMPT_GIT=""
    fi

    # ============================
    # Parse Python Virtual Env
    # ============================
    local env_name=""
    if [[ -n "$VIRTUAL_ENV" ]]; then
        env_name=$(basename "$VIRTUAL_ENV")
    elif [[ -n "$CONDA_DEFAULT_ENV" && -n "$PIXI_PROJECT_NAME" ]]; then
        env_name="cp:$CONDA_DEFAULT_ENV"
    elif [[ -n "$CONDA_DEFAULT_ENV" ]]; then
        env_name="c:$CONDA_DEFAULT_ENV"
    fi
    [[ -n "$env_name" ]] && __PROMPT_PY=" [py:$env_name]" || __PROMPT_PY=""

    # ============================
    # Parse Direnv
    # ============================
    [[ -n "$DIRENV_DIFF" ]] && __PROMPT_DIRENV=" [d]" || __PROMPT_DIRENV=""
}

function precmd() {
    # Invalidate stale state immediately to prevent ghost data 
    # when changing directories rapidly while the worker is queued
    __PROMPT_GIT=""
    __PROMPT_PY=""
    __PROMPT_DIRENV=""

    PROMPT='%B'
    PROMPT+="${COLOUR_USR}%n"
    PROMPT+="${COLOUR_AT}@"
    PROMPT+="${COLOUR_USR}%m"
    PROMPT+=" ${COLOUR_DIR}%~"

    PROMPT+="${COLOUR_GIT}\${__PROMPT_GIT}"
    PROMPT+="${COLOUR_PY}\${__PROMPT_PY}"
    PROMPT+="${COLOUR_DIR_ENV}\${__PROMPT_DIRENV}"

    PROMPT+="${COLOUR_DEF}${NEWLINE}"
    PROMPT+='~%b '

    export PROMPT

    if (( $+functions[zsh-defer] )); then
        zsh-defer -m _update_prompt_info
    else
        _update_prompt_info
    fi
}