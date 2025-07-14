# specifies wrappers around common functionality

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

        # check if running inside tmux, if so, wrap the OSC 52 sequence
        # in tmux's passthrough sequence `\ePtmux;\e...\e\\`.
        if [[ -n "$TMUX" ]]; then
            printf "\ePtmux;\e\e]52;c;%s\a\e\\" "$content_b64"
        else
            printf "\e]52;c;%s\a" "$content_b64"
        fi
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