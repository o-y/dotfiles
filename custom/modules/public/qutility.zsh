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
## qzshtime - Records how long it takes zsh to load
##
## TODO: convert this function to qtime <command> <iterations> or something similar, e.g piping.
##
qzshtime() {
    local usage() {
        echo "qzshtime - Measures Zsh Startup Latency"
        echo "Usage: qzshtime <iterations>"
        echo "  iterations    the number of commands to sample [e.g 20]"
    }

    if [[ $# -lt 1 ]]; then
        usage
        return 1
    fi

    real_times=()
    user_times=()
    sys_times=()

    iterations=$1

    echo "[qzshtime] sampling $iterations iterations..."
    echo "--- ↓"
    for i in $(seq 1 $iterations); do
        time_output=$(/usr/bin/time zsh -i -c exit 2>&1)
        
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
    echo "[qzshtime] raw data..."
    echo "--- ↓"
    echo "     real: $real_times"
    echo "     user: $user_times"
    echo "     sys: $sys_times"
    echo "--- ↑"
    echo "[qzshtime] sampled $iterations iterations..."
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
## qback - Send commands to the background
##
qback() {
    
}

