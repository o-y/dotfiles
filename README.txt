$ git clone git@github.com:o-y/dotfiles ~/dotfiles --depth 1 && cd ~/dotfiles && zsh bootstrap.zsh

--
Bootstrap config
--

Installer:
  - provides a declerative format for specifying darwin, linux and common dependencies.
  - each line expects a dependency following the notation ["dependency", "install_command"], such as:
    - "fzf" "brew install fzf"
    - "fzf" "sudo apt install fzf"
  - the dependency may include a single colon following the notation ["dependency:dependent"]. Which means the 'dependency' requires the 'dependent' to exist on the system, e.g:
    - "poetry:pipx" "pipx install poetry"    - requires 'pipx' to exist on the system to install 'poetry'
    - "foo:bar" "bar install --user foo"     - requires 'bar' to exist on the system to install 'foo'
  - the installer is ran twice, therefore a predicated instance can install a dependency which is used by successive installers.

Stower:
  - provides a declerative format for specifying darwin, linux and common config file/directory locations.
  - each line expects a package following the notation ["package", "optional - location", "optional - when:condition"]
  - each package should exist in the "packages" directory, if it exists then it is symlinked to the users $HOME directory by default, otherwise the location on the right hand side of the colon.
  - the general concept being that any configuration for any application/binary/tool should exist in a modular 'packages/foo' directory, and stow internally handles symlinking the contents, keeping both files and directories mirrored between the host and source.
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
  - stow directories may also include zsh files named "presym.hook.zsh" and "postsym.hook.zsh" which are executes before and after (where successful) stow commands, this is helpful if some amount of pre or post processing needs to happen (e.g. forceably deleting existing files, or chowning newly symlinked files after stowing, etc). see packages/atuin for an example of this

File Encryption:
  - the module system sources files via a static loader. Some files are encrypted using git-crypt, these will be ignored if not decrypted - to silence these warnings, execute 'touch ~/.silence-git-crypt-warnings'.
  - two keys exist; personal (default) and corp (secondary).

Zsh Initialization:
  - static loader (~/.zsh_static_loader.zsh) to reduce startup latency by caching the modules that should be sourced.
  - structural change detection (add/remove/rename) in custom/modules triggers regeneration of this cache, this way Zsh doesn't need to iterate through the modules directory and determine which files should be sourced every time the shell starts.
  - NOTE: I experimented with concatinating all modules into a single file and zcompiling this, but that had negligible impacts on prompt availability (literally, ~10ms) which didn't seem worth the trade-off of losing the modularity of the system. 
  - filename metadata:
    - ".nodefer." - synchronous sourcing (prompt, critical dependencies).
    - ".darwin.", ".linux." - platform filtering at cache-generation time.

File Structure:
- bootstrap.zsh       entrypoint (installer)
- packages/           configuration managed by bootstrap.zsh (stower)
- custom/init.zsh     Zsh initialization entrypoint; cache and regeneration
- custom/compiler.zsh static loader generator logic
- custom/modules/     modular config sourced by static loader
- custom/static/      resources for external programs (e.g. raycast)
- custom/postinstall/ secondary bootstrap modules (rust, py, go deps)

--
Dependencies
--

MacOS apps
  - Coding:
    - Ghostty - https://ghostty.org/
    - VS Code - https://code.visualstudio.com/download
    - Android Studio - https://developer.android.com/studio
    - Intellij Idea - https://www.jetbrains.com/idea
  - Utilities:
    - Raycast - https://raycast.com
    - Better Display - https://github.com/waydabber/BetterDisplay
    - TopNotch - https://topnotch.app
    - Dropover -  https://dropoverapp.com
    - Music Decoy - https://lowtechguys.com/musicdecoy
    - Cling - https://lowtechguys.com/cling
    - Clop - https://lowtechguys.com/clop
  - General:  
    - Anki - https://apps.ankiweb.net/
    - Discord - https://discordapp.com/download
    - Spotify - https://open.spotify.com/download

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