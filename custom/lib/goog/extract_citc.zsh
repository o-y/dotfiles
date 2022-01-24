function extract_citc_client_from_path {
    local pattern='\/google\/src\/cloud\/slyo\/(.*?)\/google3'
    local string='/google/src/cloud/slyo/webx-screenshot-prototype/google3'

    if [[ string =~ pattern ]]; then
        echo "${BASH_REMATCH[0]}"
        echo "${BASH_REMATCH[1]}"
    fi
}
