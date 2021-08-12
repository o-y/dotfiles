# track the current citc client, and if applicable change the terminal title
mkdir -p /tmp/slyo

randomNumber=$(jot -r 1 1000000 9999999)
CURRENT_CLIENT_CL_FILE="/tmp/slyo/.current_client_cl_$randomNumber"
CURRENT_CLIENT_NAME_FILE="/tmp/slyo/.current_client_name_$randomNumber"

citc_update() {
    # Only continue if in a citc client.
    if [ -x "$(command -v p4)" ]; then
        if [[ "$(p4 --format %Client% client -o)" =~ ".+:(.+):.+:.+" ]]; then
            # Write the citc client name into a file
            echo "$match" > "$CURRENT_CLIENT_NAME_FILE"
            # Write the CL number into a client or "" (blank) if null
            g4 -F'%change%' changes -c $(g4 -F'%clientName%' info) | awk 'ORS=" cl/"' | ghead -c -4 - > "$CURRENT_CLIENT_CL_FILE"
        fi
    fi
}

citc_check_update() {
    lastCommand=$(history | tail -1 | awk '{print $2}')
    if [[ $lastCommand == *"cd"* ]] || [[ $lastCommand == *"g4d"* ]]; then
        citc_update
    fi
}

citc_clear_files() {
    echo "" > "$CURRENT_CLIENT_NAME_FILE"
    echo "" > "$CURRENT_CLIENT_CL_FILE"
}

citc_clear_files

# Check if we're in a citc client...
citc_update

prompt_citc() {
    citc_check_update

    citc_name=$(<$CURRENT_CLIENT_NAME_FILE)
    current_cl=$(<$CURRENT_CLIENT_CL_FILE)

    if [[ -z "$citc_name" ]]; then
        # echo "It's empty"
    else
        p10k segment -t "g4:(%{$fg[red]%}$citc_name%{$reset_color%} / %{$fg[green]%}cl/$current_cl%{$reset_color%})"
    fi;

}