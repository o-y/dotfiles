#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title cs
# @raycast.mode silent

# Optional parameters:
# @raycast.icon ./icons/cs-logo.png
# @raycast.packageName Google Codesearch
# @raycast.argument1 { "type": "text", "placeholder": "query", "percentEncoded": true }

# Documentation:
# @raycast.description Google wide codesearch
# @raycast.author Suraj Lyons
# @raycast.authorURL zv.wtf

open "https://source.corp.google.com/search?q=$1&ct=os&sq=USE_DEFAULT_STORED_QUERY";
echo "Codesearching for: $1"