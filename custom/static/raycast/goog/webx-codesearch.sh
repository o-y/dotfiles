#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title csw
# @raycast.mode silent

# Optional parameters:
# @raycast.icon ./icons/cs-logo.png
# @raycast.packageName WebX Codesearch
# @raycast.argument1 { "type": "text", "placeholder": "query", "percentEncoded": true }

# Documentation:
# @raycast.description WebX codesearch
# @raycast.author Suraj Lyons
# @raycast.authorURL zv.wtf

open "https://cs.corp.google.com/search/?q=$1&sq=project:android.libraries.web";
echo "WebX Codesearching for: $1"