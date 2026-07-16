~~~~~~~~
autoname
~~~~~~~~

provides tabs, icons, bottom bars and other pieces of metadata, including turnkey stylization and theming

installation:
    $ cargo build --release
 OR $ cargo install --path .

usage:
    retrieve combined formatted tab representation (icon + name with colour formatting)
        $ autoname -p nvim -d ~ -c 1 -t "nvim /path/file.rs" -r tab_formatted

    retrieve a tab icon for the context [where process=nvim]
        $ autoname --process-name nvim --working-directory ~ --pane-count 1 --retrieve tab_icon

    retrieve version control status (jj / git branch with icon and colour formatting)
        $ autoname -d ~/my-repo -r vcs_formatted

    values:
        --process-name        = -p
        --working-directory   = -d
        --pane-count          = -c  (appends `[n]` badge to tab name when pane count > 1)
        --pane-title          = -t  (allows regex extraction of dynamic context in `[[process]]`)
        --retrieve            = -r  [tab_active_pill | tab_inactive_pill | tab_formatted | tab_name | tab_colour |
                                     tab_icon | tab_name_expanded | tab_active_bg | tab_divider_colour |
                                     vcs_formatted | vcs_branch | vcs_colour | vcs_icon]

ideal usage from tmux:
    # Tabs...:
    autoname -p #{pane_current_command} -c #{window_panes} -d #{pane_current_path} -t "#{pane_title}" -r tab_formatted

    # VCS Pill...:
    autoname -d #{pane_current_path} -r vcs_formatted

config:
    file: ~/.tmux/autoname.toml
    ---------------------------
    # Note: all sections ([style.font], [style.process_divider], [style.badge_divider], [panes], [processes.default],
    # [[processes.rules]], and [[directories.rules]]) are optional!
    # If omitted, built-in defaults are used. The icons are rendered using nerd fonts.
    # Note: both singular ([process.default], [[process.rules]]) and plural ([processes.default], [[processes.rules]]) forms are supported via aliases.

    # global font and typography preferences
    [style.font]
    bold = true                 # Whether primary tab names use bold typography
    text_colour = "match_icon"  # Default text color across segments: "match_icon" inherits the segment icon's color, or set a static hex string (e.g. "#bac2de")

    # process context separator (`dir › proc`)
    [style.process_divider]
    symbol = "›"                # Directional symbol separating {dir} and {proc}
    colour = "#a6adc8"          # High-contrast color for the process chevron and subtext

    # status badge separator (`title │ 󰆞 2`)
    [style.badge_divider]
    symbol = "│"                # Separator placed right before the multi-pane indicator or status badges
    colour = "#a6adc8"          # Color for the status badge pipe separator

    # multi-pane indicator customization
    [panes]
    enabled = true              # Whether to append a multi-pane indicator (`│ 󰆞 2`) when pane count > 1
    icon = "󰆞"                  # Icon displayed next to pane count
    colour = "match_left"       # "match_left" (or "inherit_left") dynamically inherits the color of the segment immediately to its left (`[current - 1]`). For example, red after `ctxm-rebuild`, yellow after `dotfiles`, or green after `dotfiles › nvim`. Can also take a static hex string (e.g. "#caaafe").

    # specifies directories which take precedence over process icons and colours
    # supports `path` or `paths`, plus `display_name_pattern` (regex), `static_display_name`, or `live_display_name`
    # if multiple directories match, the most specific (longest path prefix) is selected
    # set `exact = true` if the rule should only apply right to the literal path and not subdirectories
    [[directories.rules]]
    path = "/"
    icon = ""
    colour = "#f3f59d"
    process_context = true

    # When sitting directly in `~` (home directory), turn off process_context so `~ › cli` becomes just `cli`
    [[directories.rules]]
    path = "~"
    exact = true
    icon = ""
    colour = "#f3f59d"
    process_context = false

    [[directories.rules]]
    path = "/mnt/storage/work/"
    icon = ""
    colour = "#ea999c"
    display_name_pattern = "^/mnt/storage/work/[^/]+/([^/]+)"
    process_context = true

    [[directories.rules]]
    paths = ["~/projects/rust/", "~/work/crates/"]
    icon = ""
    static_display_name = "Rust Workspace"

    # default fallbacks for unmapped binaries
    [processes.default]
    icon = ""                  # Fallback icon when a running binary isn't mapped in `[[processes.rules]]`
    colour = "#8caaee"          # Fallback color for unmapped binaries

    # specifies process names mapped to specific icons, colours, and optional display name overrides
    # supports live template variables via `live_display_name` (e.g. `{{pwd}}`, `{{proc}}`, `{{pane_title}}`, `{{vcs_branch}}`)
    # set `ignored = true` for idle shells so the enclosing directory renders itself instead
    [[processes.rules]]
    names = ["zsh", "bash", "fish", "sh", "nu"]
    icon = ""
    ignored = true

    [[processes.rules]]
    names = ["mytool", "mytool-cli", "runner"]
    icon = ""
    colour = "#4A9A4C"
    static_display_name = "mytool" # Overrides the displayed process name so all three render as "mytool"

    [[processes.rules]]
    names = ["nvim"]
    icon = ""
    colour = "#81c8be"

    [[processes.rules]]
    names = ["cargo", "rustc"]
    icon = ""
    live_display_name = "cargo ({{pwd}})"

    [[processes.rules]]
    names = ["apt"]
    icon = ""