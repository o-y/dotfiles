~~~~~~~~
autoname
~~~~~~~~

given, principally a process_name and working_directory returns metadata which can be used to style a tmux tab

installation:
    $ cargo build --release
 OR $ cargo install --path .

usage:
    retrieve a tab icon for the context [where process=nvim]
        $ autoname --process-name nvim --working-directory ~ --pane-count 1 --retrieve tab_icon

    retrieve a tab colour for the context [where process=nvim]
        $ autoname --process-name nvim --working-directory ~ --pane-count 1 --retrieve tab_colour

    retrieve the name for the given context [where process=nvim]
        ** this provides the mechanisms to nullify process icons in favour of specific directories **
        $ autoname --process-name nvim --working-directory ~ --pane-count 1 --retrieve tab_name

    values:
        --process-name        = -p
        --working-directory   = -d
        --pane-count          = -c
        --retrieve            = -r  [tab_name | tab_colour | tab_icon]

ideal usage from tmux:
    autoname -p #{pane_current_command} -c #{window_panes} -d #{pane_current_path} -r [tab_name | tab_colour | tab_icon]

config:
    file: ~/.tmux/autoname.toml
    ---------------------------

    # specifies a default icon and colour when a process isn't found in the config
    # note: the icons are rendered using nerd fonts
    [defaults]
    process_icon = ""
    process_colour = "#8caaee"

    # specifies a number of processes mapped to icons
    [[process]]
    names = ["nvim"]
    icon = ""
    colour = "#81c8be"

    [[process]]
    names = ["cargo", "rustc"]
    icon = ""

    [[process]]
    names = ["apt"]
    icon = ""

    # specifies directories which take precedence over icons and colours
    [directories.google]
    path = "/google/src/cloud/"
    icon = ""
    colour = "#ea999c"
    extract_tab_name = "^/google/src/cloud/[^/]+/([^/]+)/google$"

    # specifes whether the default $SHELL icon and colour should be ignored in favour of
    # the current directories last parts name
    [shell_override]
    enabled = true
    shell_name = "zsh"
    icon = ""
    colour = "#e5c890"