##
## qcp - RSync wrapper
##
qcp() {
    local usage() {
        echo "qcp - Quick Network Copy"
        echo "Usage:"
        echo "  qcp push <remote> <local-path>  [remote-path]"
        echo "  qcp pull <remote> <remote-path> [local-path]"
        echo ""
        echo "Defaults:"
        echo "  [remote-path] on push defaults to '~'"
        echo "  [local-path]  on pull defaults to '.'"
    }

    if [[ $# -lt 3 ]]; then
        usage
        return 1
    fi

    local action=$1
    local remote=$2
    local src=$3
    local dest=$4

    # -a: archive mode (preserves permissions, times, symlinks, recursive)
    # -v: verbose
    # -h: human-readable numbers
    # -P: keep partially transferred files + show progress
    local rsync_opts=("-avhP")

    case "$action" in
        push)
            dest=${dest:-"~"}
            echo "[qcp] pushing local '$src' to remote '$remote:$dest'..."
            rsync "${rsync_opts[@]}" "$src" "$remote:$dest"
            ;;
        pull)
            dest=${dest:-"."}
            echo "[qcp] pulling remote '$remote:$src' to local '$dest'..."
            rsync "${rsync_opts[@]}" "$remote:$src" "$dest"
            ;;
        *)
            echo "[qcp] error: unknown action '$action', expected 'push' or 'pull'"
            usage
            return 1
            ;;
    esac
}

##
## qcp - Completions
##
_qcp() {
    # arg 1: Action
    if (( CURRENT == 2 )); then
        _values 'action' \
            'push[Copy LOCAL path -> REMOTE]' \
            'pull[Copy REMOTE path -> LOCAL]'
        return
    fi

    # arg 2: SSH Remote
    if (( CURRENT == 3 )); then
        local -a ssh_hosts
        if [[ -r ~/.ssh/config ]]; then
            # parse ~/.ssh/config for Host directives, ignoring wildcard hosts
            ssh_hosts=($(awk '/^Host[ \t]+/ {for(i=2;i<=NF;i++) if($i !~ /[*?]/) print $i}' ~/.ssh/config))
        fi
        _describe 'remote host' ssh_hosts
        return
    fi

    local action="${words[2]}"
    local target_host="${words[3]}"

    # arg 3: Source Path
    if (( CURRENT == 4 )); then
        if [[ "$action" == "push" ]]; then
            _message -e "LOCAL source path to push ->"
            _files
        elif [[ "$action" == "pull" ]]; then
            _qcp_remote_files "$target_host" "REMOTE source path to pull <-"
        fi
        return
    fi

    # arg 4: Destination Path (Optional)
    if (( CURRENT == 5 )); then
        if [[ "$action" == "push" ]]; then
            _qcp_remote_files "$target_host" "REMOTE destination path (defaults to ~) <-"
        elif [[ "$action" == "pull" ]]; then
            _message -e "LOCAL destination path (defaults to .) ->"
            _files
        fi
        return
    fi
}
compdef _qcp qcp

##
## qcp - Remote SSH Preflight File Fetcher
##
_qcp_remote_files() {
    local target_host="$1"
    local msg="$2"
    
    _message -e "$msg"
    
    [[ -z "$target_host" ]] && return

    local ls_cmd
    if [[ -z "$PREFIX" ]]; then
        # if no prefix is typed, grab visible files/dirs in home
        ls_cmd="ls -d1p ~/* 2>/dev/null"
    else
        #qQuote the prefix to safely evaluate spaces on the remote execution
        ls_cmd="ls -d1p ${(q)PREFIX}* 2>/dev/null"
    fi

    local -a remote_paths
    # use BatchMode to prevent hanging on auth prompts, and ConnectTimeout to fail fast
    remote_paths=(${(f)"$(ssh -o BatchMode=yes -o ConnectTimeout=2 "$target_host" "$ls_cmd" 2>/dev/null)"})

    if [[ ${#remote_paths[@]} -gt 0 ]]; then
        # compadd -S '' prevents zsh from automatically appending a space 
        # after a directory, allowing seamless traversal (e.g. dir1/<tab>dir2/<tab>)
        compadd -S '' -a remote_paths
    fi
}

##
## _qcp_live_hints
##
_qcp_live_hints() {
    if [[ "$BUFFER" == qcp\ * ]]; then
        _QCP_HINT_ACTIVE=1
        local -a current_words
        current_words=(${(z)BUFFER})
        
        local word_count=${#current_words[@]}
        [[ "$BUFFER" =~ " $" ]] && ((word_count++))

        local hint=""
        case $word_count in
            2) 
                hint="󰁔 action (push | pull)" 
                ;;
            3) 
                hint="󰁔 <remote> (from ~/.ssh/config)" 
                ;;
            4) 
                if [[ "${current_words[2]}" == "push" ]]; then
                    hint="󰁔 <local-path> (source to upload ->)"
                elif [[ "${current_words[2]}" == "pull" ]]; then
                    hint="󰁔 <remote-path> (source to download <-)"
                fi
                ;;
            5)
                if [[ "${current_words[2]}" == "push" ]]; then
                    hint="󰁔 [remote-path] (optional destination, defaults to ~ ($HOME))"
                elif [[ "${current_words[2]}" == "pull" ]]; then
                    hint="󰁔 [local-path] (optional destination, defaults to the current directory ($PWD))"
                fi
                ;;
        esac

        if [[ -n "$hint" ]]; then
            zle -M "$hint"
        else
            zle -M "" 
        fi
    elif (( _QCP_HINT_ACTIVE == 1 )); then
        _QCP_HINT_ACTIVE=0
        zle -M ""
    fi
}

autoload -Uz add-zle-hook-widget
add-zle-hook-widget line-pre-redraw _qcp_live_hints