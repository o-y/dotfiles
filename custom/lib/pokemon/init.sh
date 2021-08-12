#!/bin/sh

PATH_TO_SCRIPT=`realpath -s "$0"`
PATH_TO_SCRIPT_DIR=`dirname "$PATH_TO_SCRIPT"`

cat $(find $PATH_TO_SCRIPT_DIR/asciiart -type f | shuf -n 1)