#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Restart Yabai
# @raycast.mode silent

# Optional parameters:
# @raycast.icon ⌨️
# @raycast.packageName Restart Yabai

# Documentation:
# @raycast.description Restart Yabai
# @raycast.author Suraj Lyons
# @raycast.authorURL zv.wtf

launchctl kickstart -k "gui/${UID}/homebrew.mxcl.yabai"