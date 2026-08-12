#!/usr/bin/env zsh

# Is the current window stacked? (0 = no)
IS_STACKED=$(yabai -m query --windows --window | jq '.["stack-index"]')

if [[ "$IS_STACKED" -eq 0 ]]; then
    # NOT STACKED: Collapse it with a neighbor
    yabai -m window --stack south || yabai -m window --stack east || \
    yabai -m window --stack north || yabai -m window --stack west
else
    # STACKED: Eject it from the node in place
    
    # We must grab the ID, because pulling a window out of a stack 
    # immediately drops your focus to the window beneath it.
    WIN_ID=$(yabai -m query --windows --window | jq '.id')

    # Prepare the split, eject it, and re-insert it natively
    yabai -m window --insert south
    yabai -m window "$WIN_ID" --toggle float
    yabai -m window "$WIN_ID" --toggle float
    
    # Grab focus back
    yabai -m window --focus "$WIN_ID"
fi