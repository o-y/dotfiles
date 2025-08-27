# this should be ran the first time these files are symlinked
# though it doesn't matter if it executes every time because
# it's not bi-directional.
# effectively atuin regenerates its own config file each time
# a command is ran, meaning we don't actuall symlink the 
# vendored instance.

rm -rf ~/.config/atuin/config.toml
zsh ~/dotfiles/bootstrap.zsh