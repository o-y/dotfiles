/// Canonical definitions for built-in default icons (Nerd Font symbols).
pub mod icons {
    /// Folder icon used for directories and folder display.
    pub const FOLDER: &str = "";
    /// Terminal / shell icon used as the default fallback for processes.
    pub const TERMINAL: &str = "";
    /// Multi-pane indicator icon used when a window has multiple panes.
    pub const MULTI_PANE: &str = "󰆞";
    /// JJ (Jujutsu) version control icon.
    pub const JJ: &str = "";
    /// Git version control icon.
    pub const GIT: &str = "";
    /// Error / fallback icon used when queries encounter errors or missing data.
    pub const ERROR: &str = "󱎘";
    /// CPU / processor icon used for overall CPU usage.
    pub const CPU: &str = "";
    /// Network / port listening icon used for active TCP ports.
    pub const PORT: &str = "󰖪";
    /// Job / suspended process icon used for stopped background tasks (`Ctrl+Z`).
    pub const JOB: &str = "󰏤";
    /// Build / compile toolchain icon used for active blaze / cargo builds.
    pub const BUILD: &str = "󰑮";
}

/// Canonical definitions for fallback texts.
pub mod texts {
    /// Standard fallback text displayed when metadata is unavailable or errored.
    pub const NA: &str = "! N/A !";
}

/// Canonical definitions for built-in default colours (hex strings).
pub mod colours {
    /// Soft blue used as the default process fallback colour.
    pub const BLUE: &str = "#8caaee";
    /// Bright yellow used as the default directory / folder colour.
    pub const YELLOW: &str = "#f3f59d";
    /// Lavender / mauve used as the default multi-pane badge colour and JJ colour.
    pub const MAUVE: &str = "#caaafe";
    /// Soft green used for Git repositories and listening ports.
    pub const GREEN: &str = "#a6d189";
    /// Soft peach / orange used for CPU utilization.
    pub const PEACH: &str = "#fab387";
    /// Red colour used for error or fallback display.
    pub const ERROR: &str = "#ff6e6f";
    /// Muted grey-blue used as the default divider symbol colour.
    pub const DIVIDER_GREY: &str = "#a6adc8";
    /// Light grey-blue used as the default font subtext colour.
    pub const SUBTEXT_LIGHT: &str = "#bac2de";
    /// Subtext colour used for branch names in VCS output.
    pub const VCS_SUBTEXT: &str = "#c6d0f5";
    /// Bright white-grey used as the default multi-pane count number colour.
    pub const PANE_COUNT_LIGHT: &str = "#e5e9f0";
}

/// Canonical definitions for built-in divider and badge symbols.
pub mod symbols {
    /// Separates directory and process context in combined tab titles.
    pub const CHEVRON_RIGHT: &str = "›";
    /// Separates the main title from the multi-pane indicator badge.
    pub const VERTICAL_PIPE: &str = "│";
}

/// Canonical definitions for built-in process lists.
pub mod processes {
    /// Standard interactive shell names that default to being ignored.
    pub const BUILTIN_SHELLS: &[&str] = &["zsh", "bash", "fish", "sh", "nu"];
}

/// Canonical definitions for tmux formatting strings and pill construction helpers.
pub mod tmux {
    pub const STATUS_BG: &str = "#{@status_background}";
    pub const TERMINAL_BG: &str = "#{@terminal_background}";
    pub const STATUS_SEP_LEFT: &str = "#{@status_separator_left}";
    pub const STATUS_SEP_RIGHT: &str = "#{@status_separator_right}";

    pub const WINDOW_ACTIVE_COLOUR: &str = "#{@window_active_colour}";
    pub const WINDOW_INACTIVE_COLOUR: &str = "#{@window_inactive_colour}";
    pub const WINDOW_SEP_LEFT: &str = "#{@window_separator_left}";
    pub const WINDOW_SEP_RIGHT: &str = "#{@window_separator_right}";
    pub const PANE_INACTIVE_BORDER: &str = "#{@pane_inactive_border}";

    /// Wraps formatted inner text inside a tmux background oval pill (`...`).
    pub fn format_pill(
        fg_outer: &str,
        bg_outer: &str,
        bg_pill: &str,
        sep_left: &str,
        inner: &str,
        sep_right: &str,
    ) -> String {
        format!(
            "#[fg={fg_outer},bg={bg_outer}]{sep_left}#[bg={bg_pill}]{inner}#[fg={fg_outer},bg={bg_outer}]{sep_right}"
        )
    }
}
