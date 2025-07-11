$ git clone git@github.com:o-y/dotfiles ~/dotfiles --depth 1 && cd ~/dotfiles && zsh ./bootstrap.zsh

--
Bootstrap config
--

Installer:
  - provides a declerative format for specifying darwin, linux and common dependencies using arrays named so.
  - each line expects a dependency following the notation ["dependency", "install_command"], such as:
    - "fzf" "brew install fzf"
    - "fzf" "sudo apt install fzf"
  - additionally the dependency can include a single colon following the notation ["dependency:dependent"]. Which means for a given 'dependency' to install, the 'dependent' must too exist on the system, e.g:
    - "thefuck:pipx" "pipx install thefuck"  - requires 'pipx' to exist on the system
    - "foo:bar" "bar install --user foo"     - requires 'bar' to exist on the system

Stower:
  - provides a declerative format for specifying darwin, linux and common config file/directory locations using arrays named so (essentially the installer but for symlinking files).
  - each line expects a dependency (package) following the notation ["dependency:location"], where location is optional.
  - each package should exist in the "packages" directory, if it exists then it is symlinked to ~/ by default, otherwise the location on the right hand side of the colon.
  - the general concept being that any configuration for any application/binary/tool should exist in a modular 'packages/foo' directory, and stow internally handles symlinking the contents, keeping both files and directories mirrored between the host and the repo.
  - e.g:
    - "blaze"                    - contents symlinked to ~/
    - "hgrc"                     - contents symlinked to ~/
    - "zellij:~/.config/zellij"  - contents symlinked to ~/.config/zellij
    - "helix:~/.config/helix"    - contents symlinked to ~/.config/helix

File Encryption:
  - The module system sources files at startup in custom/modules. Some files are encrypted using git-crypt, these will be ignored if not decrypted - to silence these warnings, execute 'touch ~/.silence-git-crypt-warnings'.

File Structure:
- bootstrap.zsh       entrypoint (installer)
- packages:           dotfiles/configuration managed by the boostrap.zsh file (stower)
- custom/modules:     files that are automatically sourced at session init
- custom/static:      static resources/scripts required by external programs (e.g raycast)
- custom/postinstall: files that are automatically sourced with the bootstrap.zsh flow (e.g installing rust, go behind confirmation dialogues)

--
Dependencies
--

MacOS apps
  - Ghostty - https://ghostty.org/
  - Raycast - https://raycast.com
  - Better Display - https://github.com/waydabber/BetterDisplay
  - TopNotch - https://topnotch.app
  - VS Code - https://code.visualstudio.com/download
  - Anki - https://apps.ankiweb.net/
  - Discord - https://discordapp.com/download
  - Spotify - https://open.spotify.com/download
  - Android Studio - https://developer.android.com/studio

MacOS dependencies
  - Brew - https://brew.sh
  - Yabai - https://github.com/koekeishiya/yabai
  - Skhd - https://github.com/koekeishiya/skhd

Common dependencies
  - Zsh - https://github.com/ohmyzsh/ohmyzsh/wiki/Installing-ZSH

--
Application Config
--

Visual Studio Code:
  - Theme: Bearded Theme - Arc
  - Icons Theme: Bearded Icons