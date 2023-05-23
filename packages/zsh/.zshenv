# Allow zsh to handle '*' like bash
setopt nonomatch

# Cargo
if [ -f "$HOME/.cargo/env" ]; then
    . "$HOME/.cargo/env"
fi

if [ -e /usr/local/google/home/slyo/.nix-profile/etc/profile.d/nix.sh ]; then . /usr/local/google/home/slyo/.nix-profile/etc/profile.d/nix.sh; fi # added by Nix installer
