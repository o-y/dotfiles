$ git clone git@github.com:o-y/dotfiles ~/dotfiles --depth 1 && cd ~/dotfiles && zsh ./bootstrap.zsh

--
Bootstrap config
--

Installer:
  - provides a declerative format for specifying darwin, linux and common dependencies.
  - each line expects a dependency following the notation ["dependency", "install_command"], such as:
    - "fzf" "brew install fzf"
    - "fzf" "sudo apt install fzf"
  - the dependency may include a single colon following the notation ["dependency:dependent"]. Which means the 'dependent' requires the 'dependent' to exist on the system, e.g:
    - "poetry:pipx" "pipx install poetry"    - requires 'pipx' to exist on the system to install 'poetry'
    - "foo:bar" "bar install --user foo"     - requires 'bar' to exist on the system to install 'foo'
  - the installer is ran twice, therefore a predicated instance can install a dependency which is used by successive installers.

Stower:
  - provides a declerative format for specifying darwin, linux and common config file/directory locations.
  - each line expects a package following the notation ["package", "optional - location", "optional - when:condition"]
  - each package should exist in the "packages" directory, if it exists then it is symlinked to ~/ by default, otherwise the location on the right hand side of the colon.
  - the general concept being that any configuration for any application/binary/tool should exist in a modular 'packages/foo' directory, and stow internally handles symlinking the contents, keeping both files and directories mirrored between the host and the repo.
  - e.g:
    - "blaze"                    - contents symlinked to ~/
    - "hgrc"                     - contents symlinked to ~/
    - "zellij:~/.config/zellij"  - contents symlinked to ~/.config/zellij
    - "helix:~/.config/helix"    - contents symlinked to ~/.config/helix
  - an optional "when" condition may be applied, this means the config is only stowed if the predicate is true. which is useful for contextually specific (e.g. hostname, environment, mac address, etc) pieces of configuration. the symbol on the right hand side of the 'when' condition should point to a truthy expression.
  - e.g:
    $ is_google() [[ "$(hostname)" =~ '\.corp\.goo(gle|glers)\.com$' ]]
    - "jj/google    when: is_google"
    - "jj/personal  when: ! is_google" 
  - multiple stows may point to the same directory, and the right hand part of the stow (i.e. the package) may itself be a nested directory. in the example below the 'ghostty/base' config maintains shared logic with an optional source that points to a platform-specific file which is stowed based on the conditions of the 'when' statement.
    $ function is_macos() [[ "$(uname)" == "Darwin" ]]
    $ function is_linux() [[ "$(uname)" == "Linux" ]]
    - "ghostty/base:~/.config/ghostty"
    - "ghostty/linux:~/.config/ghostty when: is_linux"
    - "ghostty/macos:~/.config/ghostty when: is_macos"

File Encryption:
  - the module system sources files at startup in custom/modules. Some files are encrypted using git-crypt, these will be ignored if not decrypted - to silence these warnings, execute 'touch ~/.silence-git-crypt-warnings'.
  - two keys exist; personal (default) and corp (secondary).

File Structure:
- bootstrap.zsh       entrypoint (installer)
- packages:           dotfiles/configuration managed by the boostrap.zsh file (stower)
- custom/modules:     files that are automatically sourced at session init
  - these files may include metadata in the same such as "foo.corp.zsh" or "bar.linux.zsh" which signifies the former is encrypted via git-crypt and the latter should only run if executing within a Linux environment
- custom/static:      static resources/scripts required by external programs (e.g raycast)
- custom/postinstall: files that are automatically sourced with the bootstrap.zsh flow (e.g installing rust, go, python dependencies, etc behind confirmation dialogues)

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