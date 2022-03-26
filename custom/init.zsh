PATH_TO_SCRIPT=`realpath -s "$0"`
PATH_TO_SCRIPT_DIR=`dirname "$PATH_TO_SCRIPT"`
PUBLIC_MODULES="$PATH_TO_SCRIPT_DIR/modules/public"    # public
PRIVATE_MODULES="$PATH_TO_SCRIPT_DIR/modules/private"  # private exports, etc
GOOG_MODULES="$PATH_TO_SCRIPT_DIR/modules/goog"        # goog related functionality

[ -d $PUBLIC_MODULES ] && for file in $PUBLIC_MODULES/*; do source $file; done;
[ -d $PRIVATE_MODULES ] && for file in $PRIVATE_MODULES/*; do source $file; done;
[ -d $GOOG_MODULES ] && for file in $GOOG_MODULES/*; do source $file; done;
