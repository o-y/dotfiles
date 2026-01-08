# various useful utility functions

##
## qrepeat - Command Repeater
##
qrepeat() {
    local usage() {
        echo "qrepeat - Command Repeater"
        echo "Usage: qrepeat <interval> <command>"
        echo "  interval    time between each command [e.g 5s, 2m, 1h, 3d]"
        echo "  command     the command which should be executed" 
    }

    local time_to_seconds() {
        local time_notation=$1
        local num=${time_notation%[a-zA-Z]*}
        local unit=${time_notation//[0-9.]}

        if ! [[ $num =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
            echo "[qrepeat] invalid time notation: $time_notation"
            usage
            return 1
        fi

        case $unit in
            "s") echo "$num";;
            "m") echo "$((num * 60))";;
            "h") echo "$((num * 3600))";;
            "d") echo "$((num * 86400))";;
            *) echo "[qrepeat] invalid time notation: $time_notation"
            usage
            return 1;;
        esac
    }

    if [[ $# -lt 2 ]]; then
        usage
        return 1
    fi

    local interval=$(time_to_seconds $1)
    shift
    local command=$@

    echo "[qrepeat]: executing every $interval second(s): $command"
    while true; do
        eval $command
        sleep $interval
    done
}

##
## qtime - Records how long it takes a command to run
##
qtime() {
    local usage() {
        echo "qtime - Measures Command Execution Times"
        echo "Usage: qtime <command> <iterations>"
        echo "  command       the command to run"
        echo "  iterations    the number of commands to sample where n >= 3 [e.g 20]"
    }

    if [[ $# -lt 2 ]]; then
        usage
        return 1
    fi

    command="$1"
    iterations="$2"

    # Input validation: Check if iterations is a positive integer greater than 2
    if [[ ! "$iterations" =~ ^[2-9][0-9]*$ ]]; then
        echo "[qtime] error: iterations must be an integer >= 3."
        return 1
    fi

    # Input validation: Check if command is at least one non-space character
    if [[ -z "${command// /}" ]]; then
        echo "[qtime] error: command must be at least one non-space character."
        return 1
    fi

    real_times=()
    user_times=()
    sys_times=()

    echo "[qtime] sampling $iterations iterations of '$command'..."
    echo "--- ↓"
    for i in $(seq 1 $iterations); do
        # OLD - time_output=$(/usr/bin/time zsh -i -c exit 2>&1)
        # RAW - time_output=$(eval "/usr/bin/time $command" 2>&1)

        # TODO: At the moment this involves creating a zsh session, which doesn't matter too much
        # as generally I'm more interested in the relative differences between commands rather
        # than individual absolute metrics.
        time_output=$(eval "/usr/bin/time zsh -i -c $command exit" 2>&1)
        
        [[ $time_output =~ '([0-9.]+) real' ]] && real_times+=("${match[1]}")
        [[ $time_output =~ '([0-9.]+) user' ]] && user_times+=("${match[1]}")
        [[ $time_output =~ '([0-9.]+) sys' ]] && sys_times+=("${match[1]}")

        echo "     iteration $i/$iterations"
    done
    echo "--- ↑"

    # --- mean ---
    local mean() {
        local sum=0 total=$#
        for val in "$@"; do
            sum=$(bc <<< "$sum + $val * 100")
        done
        printf "%.2f\n" $(bc -l <<< "$sum / $total / 100")
    }
    mean_real=$(mean "${real_times[@]}")
    mean_user=$(mean "${user_times[@]}")
    mean_sys=$(mean "${sys_times[@]}")

    # --- median ---
    local median() {
        local sorted=($(printf '%s\n' "$@" | sort -n))
        local middle=$(((${#sorted[@]} + 1) / 2))
        if (( ${#sorted[@]} % 2 == 0 )); then
            printf "%.2f\n" $(bc -l <<< "(${sorted[$middle - 1]} + ${sorted[$middle]}) / 2")
        else
            printf "%.2f\n" "${sorted[$middle - 1]}" 
        fi
    }
    median_real=$(median "${real_times[@]}")
    median_user=$(median "${user_times[@]}")
    median_sys=$(median "${sys_times[@]}")

    # --- output ---
    echo "[qtime] raw data..."
    echo "--- ↓"
    echo "     real: $real_times"
    echo "     user: $user_times"
    echo "     sys: $sys_times"
    echo "--- ↑"
    echo "[qtime] sampled $iterations iterations of '$command'..."
    echo "--- ↓"
    echo "     mean real: $mean_real"
    echo "     mean user: $mean_user"
    echo "     mean sys:  $mean_sys"
    echo "     ---"
    echo "     median real: $median_real"
    echo "     median user: $median_user"
    echo "     median sys:  $median_sys"
    echo "--- ↑"
}

##
## copy - universal platform/connection/tmux agonistic clipboard integration
##
copy() {
    # --- Usage Info ---
    local usage() {
        echo "copy - universal copy to clipboard utility" >&2
        echo "Usage:" >&2
        echo "  pipe to copy: <command> | copy" >&2
        echo "  copy a file:  copy <file>" >&2
    }

    if [ -t 0 ] && [ $# -eq 0 ]; then
        usage
        return 1
    fi

    # read all input from stdin (pipe) or file arguments into a variable
    # which prevents issues with commands that might close stdin prematurely
    local input_data=$({ cat "$@" || cat; })

    if [[ -z "$input_data" ]]; then
        echo "[copy] error: empty input data"
        return 0
    fi

    # case 1: executing within an SSH session (use OSC 52)
    if [[ -n "$SSH_CLIENT" || -n "$SSH_TTY" ]]; then
        local B64_ARGS=""
        if [[ "$(uname)" == "Linux" ]]; then
            B64_ARGS="-w0"
        fi
        
        local content_b64=$(echo -n "$input_data" | base64 $B64_ARGS)

        # ideally we'd only need to wrap the OSC 52 sequence in the
        # tmux passthrough sequence if we are in a TMUX session, however
        # without some form of env variable forwarding this can't be
        # reliably detected, as an ssh session may exist within a local
        # tmux session. 
        # therefore we take the OSC 52 sequence:
        #    "\e]52;c;%s\a" "$content_b64"
        # and wrap it in the tmux passthrough:
        #    "\ePtmux;\e...\\\"
        # to form:
        #     "\ePtmux;\e" + (OSC 52 sequence) + "\e\\"
        # OR  "\ePtmux;\e\e]52;c;%s\a\e\\"

        # TODO - I should work out a reusable mechanism for environment
        # variable forwarding, then if the local and remote sessions are
        # both tmux, we can send more escape sequences so copy still works
        # (which is cursed as fuck) - https://unix.stackexchange.com/a/556764

        printf "\ePtmux;\e\e]52;c;%s\a\e\\" "$content_b64"
        return
    fi

    # case 2 - executing on a local machine
    case "$(uname)" in
        Darwin)
            echo -n "$input_data" | pbcopy
        ;;
        Linux)
            if command -v wl-copy &> /dev/null; then
                echo -n "$input_data" | wl-copy
            elif command -v xclip &> /dev/null; then
                echo -n "$input_data" | xclip -selection clipboard
            else
                echo "[copy] error: ensure 'wl-copy' (Wayland) or 'xclip' (X11) is installed" >&2
                return 1
            fi
        ;;
    *)
        echo "[copy] error: unsupported local operating system - $(uname)" >&2
        return 1
        ;;
    esac
}
alias qopy=copy

##
## qlock - File/Alias Permission Locker
##
typeset -gA _QLOCK_ALIASES
_QLOCK_ALIASES=(
    # because various installers find it fit to
    # fuck the contents of my zshrc and zshenv
    # files.
    "zsh"   "$HOME/.zshrc $HOME/.zshenv"
)
qlock() {
    local usage() {
        echo "qlock - File Permission Locker"
        echo "Usage: qlock <on|off|status> <target>"
        echo "  on        removes write permissions (chmod a-w)"
        echo "  off       restores user write permissions (chmod u+w)"
        echo "  status    checks current writability"
        echo "  target    a file path, directory, or alias"
        echo ""
        echo "Defined Aliases:"
        for key val in "${(@kv)_QLOCK_ALIASES}"; do
            printf "  %-9s -> %s\n" "$key" "$val"
        done
    }

    if [[ $# -lt 2 ]]; then
        usage
        return 1
    fi

    local action=$1
    local target=$2
    local paths=()

    if [[ -n "${_QLOCK_ALIASES[$target]}" ]]; then
        paths=(${(z)_QLOCK_ALIASES[$target]})
    else
        paths=("$target")
    fi

    for item in "${paths[@]}"; do
        item=${~item}

        if [[ ! -e "$item" ]]; then
            echo "[qlock] error: '$item' does not exist"
            continue
        fi

        case "$action" in
            "on")
                chmod a-w "$item"
                echo "[qlock] locked: $item (a-w)"
                ;;
            "off")
                chmod u+w "$item"
                echo "[qlock] unlocked: $item (u+w)"
                ;;
            "status")
                if [[ -w "$item" ]]; then
                    echo "[qlock] WRITABLE:   $item"
                else
                    echo "[qlock] READ-ONLY:  $item"
                fi
                ;;
            *)
                echo "[qlock] error: unknown action '$action'"
                usage
                return 1
                ;;
        esac
    done
}
_qlock() {
    local line
    _arguments -C \
        "1:action:(on off status)" \
        "2:target:->targets"

    case $state in
        targets)
            _alternative \
                "aliases:alias:(${(k)_QLOCK_ALIASES})" \
                "files:file:_files"
            ;;
    esac
}
compdef _qlock qlock