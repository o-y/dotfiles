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