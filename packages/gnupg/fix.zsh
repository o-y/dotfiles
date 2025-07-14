# if you see errors such as "unsafe permissions on homedir"
# whilst running gpg related commands, then fun this script
# these errors occur because the vendoring of files does not
# respect certain requirements, such as only user-readable
# permissions that the gpg agent requires. perhaps the notion
# of hooks should be added to specific stows...
#
# reference: https://askubuntu.com/a/1539606 - Olek Wojnar

echo "[gpg] chowning ~/.gpupg"

chown -R $(whoami) ~/.gnupg/
find ~/.gnupg -type d -exec chmod 700 {} \;
find ~/.gnupg -type f -exec chmod 600 {} \;

