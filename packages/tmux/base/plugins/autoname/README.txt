~~~~~~~~
autoname
~~~~~~~~

given, principally a process_name and working_directory returns metadata which can be used to style a tmux tab.

installation:
    $ cargo build --release
    $ cargo install --path .

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

ideal usage:
    pipe