use crate::appearance::{format_text, SegmentBuffer, SegmentSpan};
use crate::config::domain::{AppConfig, DirectoryInfo, ProcessInfo};
use crate::constants::{colours, icons};
use crate::tabs::template::TemplateContext;
use std::path::Path;

/// Defines the final, canonical representation of a process's metadata,
/// used throughout the application after parsing.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct TabAppearance {
    pub icon: String,
    pub colour: String,
    pub name: String,
    pub name_formatted: String,
}

impl TabAppearance {
    /// Computes the tab appearance based on the process name, working directory, pane count, pane title, and app config.
    pub fn compute(
        process_name: &str,
        working_directory: &str,
        pane_count: u8,
        pane_title: &str,
        config: &AppConfig,
    ) -> Self {
        let working_dir = Path::new(working_directory);
        let ctx = TemplateContext::new(working_dir, process_name, pane_title);

        let render_mode = RenderMode::determine(config, working_dir, process_name);
        let mut appearance = render_mode.render(&ctx, config);

        let decorators: &[&dyn TabDecorator] = &[&MultiPaneBadgeDecorator];
        for decorator in decorators {
            decorator.decorate(&mut appearance, &ctx, pane_count, config);
        }

        Self {
            icon: appearance.icon,
            colour: appearance.colour,
            name: appearance.name,
            name_formatted: appearance.name_formatted,
        }
    }
}

/// Represents the resolved base visual elements of a tab before decorators are applied.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct BaseAppearance {
    pub icon: String,
    pub colour: String,
    pub name: String,
    pub name_formatted: String,
    pub segments: SegmentBuffer,
}

/// A trait for pluggable components that decorate or enrich `BaseAppearance` with additional metadata or formatted output.
pub trait TabDecorator {
    fn decorate(&self, appearance: &mut BaseAppearance, ctx: &TemplateContext, pane_count: u8, config: &AppConfig);
}

/// Decorator that appends a multi-pane indicator badge (`│ 󰆞 3`) when a window has multiple panes.
pub struct MultiPaneBadgeDecorator;

impl TabDecorator for MultiPaneBadgeDecorator {
    fn decorate(&self, appearance: &mut BaseAppearance, _ctx: &TemplateContext, pane_count: u8, config: &AppConfig) {
        if pane_count <= 1 || !config.panes.enabled {
            return;
        }

        let previous_colour = appearance.segments.previous().map(|s| s.colour.as_str());
        let pane_col = config.panes.resolve_colour(previous_colour);

        let div_sym = &config.style.badge_divider.symbol;
        let div_col = &config.style.badge_divider.colour;
        let pane_icon = &config.panes.icon;
        let count_col = if config.style.font.text_colour.eq_ignore_ascii_case("match_icon") {
            Some(pane_col)
        } else {
            Some(config.style.font.text_colour.as_str())
        };

        let badge_plain = format!(" {div_sym} {pane_icon} {pane_count}");
        let count_fmt = format_text(&pane_count.to_string(), count_col, true);
        let badge_formatted = format!(
            " #[fg={div_col}]{div_sym} #[fg={pane_col}]{pane_icon} {count_fmt}",
            div_col = div_col,
            div_sym = div_sym,
            pane_col = pane_col,
            pane_icon = pane_icon,
            count_fmt = count_fmt
        );

        appearance.name.push_str(&badge_plain);
        appearance.name_formatted.push_str(&badge_formatted);
        appearance.segments.push(SegmentSpan {
            text: pane_count.to_string(),
            icon: Some(pane_icon.clone()),
            colour: pane_col.to_string(),
            text_colour: count_col.map(|s| s.to_string()),
            bold: true,
        });
    }
}

enum RenderMode<'a> {
    DirectoryOnly { dir: Option<&'a DirectoryInfo> },
    CombinedContext {
        dir: &'a DirectoryInfo,
        proc: Option<&'a ProcessInfo>,
    },
    ProcessOnly { proc: Option<&'a ProcessInfo> },
}

impl<'a> RenderMode<'a> {
    pub fn determine(config: &'a AppConfig, working_dir: &Path, process_name: &str) -> Self {
        let dir_info = config.find_directory(working_dir);
        let proc_info = config.find_process(process_name);
        let is_ignored = proc_info.map(|p| p.is_ignored()).unwrap_or(false);

        match (dir_info, is_ignored) {
            (_, true) => Self::DirectoryOnly { dir: dir_info },
            (Some(dir), false) if dir.should_show_process_context() => {
                Self::CombinedContext { dir, proc: proc_info }
            }
            (_, false) => Self::ProcessOnly { proc: proc_info },
        }
    }

    pub fn render(&self, ctx: &TemplateContext, config: &AppConfig) -> BaseAppearance {
        match self {
            Self::DirectoryOnly { dir } => render_directory_only(*dir, ctx, config),
            Self::CombinedContext { dir, proc } => render_combined_context(dir, *proc, ctx, config),
            Self::ProcessOnly { proc } => render_process_only(*proc, ctx, config),
        }
    }
}

fn render_directory_only(
    dir: Option<&DirectoryInfo>,
    ctx: &TemplateContext,
    config: &AppConfig,
) -> BaseAppearance {
    let (dir_name, icon, colour, text_col, bold) = match dir {
        Some(dir_info) => (
            dir_info.resolve_tab_name(ctx.working_dir, ctx),
            if dir_info.icon().is_empty() {
                config
                    .find_process(ctx.process_name)
                    .map(|p| p.icon().to_string())
                    .unwrap_or_else(|| icons::FOLDER.to_string())
            } else {
                dir_info.icon().to_string()
            },
            dir_info.colour().to_string(),
            if config.style.font.text_colour.eq_ignore_ascii_case("match_icon") {
                dir_info.colour().to_string()
            } else {
                config.style.font.text_colour.clone()
            },
            dir_info.bold(&config.style),
        ),
        None => (
            format_directory_path(ctx.working_dir),
            icons::FOLDER.to_string(),
            colours::YELLOW.to_string(),
            if config.style.font.text_colour.eq_ignore_ascii_case("match_icon") {
                colours::YELLOW.to_string()
            } else {
                config.style.font.text_colour.clone()
            },
            config.style.font.bold,
        ),
    };

    let name_formatted = format_text(&dir_name, Some(&text_col), bold);
    BaseAppearance {
        icon: icon.clone(),
        colour: colour.clone(),
        name: dir_name.clone(),
        name_formatted,
        segments: SegmentBuffer::new(vec![SegmentSpan {
            text: dir_name,
            icon: Some(icon),
            colour,
            text_colour: Some(text_col),
            bold,
        }]),
    }
}

fn render_process_only(
    proc: Option<&ProcessInfo>,
    ctx: &TemplateContext,
    config: &AppConfig,
) -> BaseAppearance {
    let (name, icon, colour, text_col, bold) = match proc {
        Some(proc_info) => (
            proc_info.resolve_tab_name(ctx.process_name, ctx.pane_title, ctx),
            proc_info.icon().to_string(),
            proc_info.colour().to_string(),
            if config.style.font.text_colour.eq_ignore_ascii_case("match_icon") {
                proc_info.colour().to_string()
            } else {
                config.style.font.text_colour.clone()
            },
            proc_info.bold(&config.style),
        ),
        None => (
            ctx.process_name.to_string(),
            config.process.default.icon.clone(),
            config.process.default.colour.clone(),
            if config.style.font.text_colour.eq_ignore_ascii_case("match_icon") {
                config.process.default.colour.clone()
            } else {
                config.style.font.text_colour.clone()
            },
            config.style.font.bold,
        ),
    };

    let name_formatted = format_text(&name, Some(&text_col), bold);
    BaseAppearance {
        icon: icon.clone(),
        colour: colour.clone(),
        name: name.clone(),
        name_formatted,
        segments: SegmentBuffer::new(vec![SegmentSpan {
            text: name,
            icon: Some(icon),
            colour,
            text_colour: Some(text_col),
            bold,
        }]),
    }
}

fn render_combined_context(
    dir: &DirectoryInfo,
    proc: Option<&ProcessInfo>,
    ctx: &TemplateContext,
    config: &AppConfig,
) -> BaseAppearance {
    let dir_name = dir.resolve_tab_name(ctx.working_dir, ctx);
    let proc_name = proc
        .map(|p| p.resolve_tab_name(ctx.process_name, ctx.pane_title, ctx))
        .unwrap_or_else(|| ctx.process_name.to_string());

    let proc_icon = proc
        .map(|p| p.icon().to_string())
        .unwrap_or_else(|| config.process.default.icon.clone());
    let proc_colour = proc
        .map(|p| p.colour().to_string())
        .unwrap_or_else(|| config.process.default.colour.clone());

    let proc_text_colour = if config.style.font.text_colour.eq_ignore_ascii_case("match_icon") {
        &proc_colour
    } else {
        &config.style.font.text_colour
    };
    let proc_bold = proc
        .map(|p| p.bold(&config.style))
        .unwrap_or(config.style.font.bold);
    let proc_formatted = format!(
        "#[fg={proc_colour}]{proc_icon} {proc_text}",
        proc_colour = proc_colour,
        proc_icon = proc_icon,
        proc_text = format_text(&proc_name, Some(proc_text_colour), proc_bold)
    );

    let div_colour = &config.style.process_divider.colour;
    let div_sym = &config.style.process_divider.symbol;
    let sub_col = if config.style.font.text_colour.eq_ignore_ascii_case("match_icon") {
        dir.colour()
    } else {
        &config.style.font.text_colour
    };
    let styled_divider = format!(
        " #[fg={div_colour}]{div_sym} #[fg={sub_col}]",
        div_colour = div_colour,
        div_sym = div_sym,
        sub_col = sub_col
    );

    let dir_text_colour = if config.style.font.text_colour.eq_ignore_ascii_case("match_icon") {
        dir.colour()
    } else {
        &config.style.font.text_colour
    };
    let dir_bold = dir.bold(&config.style);
    let dir_formatted = format_text(&dir_name, Some(dir_text_colour), dir_bold);

    let name = dir.format_process_tab(&dir_name, &proc_name, &config.style);
    let name_formatted = format!(
        "{dir_formatted}{styled_divider}{proc_formatted}",
        dir_formatted = dir_formatted,
        styled_divider = styled_divider,
        proc_formatted = proc_formatted
    );

    let icon = if dir.icon().is_empty() {
        proc_icon.clone()
    } else {
        dir.icon().to_string()
    };

    BaseAppearance {
        icon: icon.clone(),
        colour: dir.colour().to_string(),
        name,
        name_formatted,
        segments: SegmentBuffer::new(vec![
            SegmentSpan {
                text: dir_name,
                icon: if dir.icon().is_empty() { None } else { Some(dir.icon().to_string()) },
                colour: dir.colour().to_string(),
                text_colour: Some(dir_text_colour.to_string()),
                bold: dir_bold,
            },
            SegmentSpan {
                text: proc_name,
                icon: Some(proc_icon),
                colour: proc_colour.clone(),
                text_colour: Some(proc_text_colour.to_string()),
                bold: proc_bold,
            },
        ]),
    }
}

/// Formats a directory path for display (`~` for home, or the final component).
pub fn format_directory_path(path: &Path) -> String {
    if let Some(home_dir) = dirs::home_dir()
        && path == home_dir
    {
        return "~".to_string();
    }

    path.file_name()
        .and_then(|name| name.to_str())
        .map(String::from)
        .unwrap_or_else(|| path.to_string_lossy().into_owned())
}

/// Formats an expanded directory path for display (`/usr/local/bin` -> `/usr/l/bin`).
pub fn format_expanded_directory_path(path: &Path) -> String {
    if path == Path::new("/") {
        return "/".to_string();
    }

    let home_dir = dirs::home_dir();
    let (prefix, path_to_format) = match home_dir {
        Some(ref home) if path == home => return "~".to_string(),
        Some(ref home) => match path.strip_prefix(home) {
            Ok(stripped) => ("~/", stripped),
            Err(_) => ("/", path),
        },
        None => ("/", path),
    };

    let mut components: Vec<_> = path_to_format
        .components()
        .filter_map(|c| c.as_os_str().to_str())
        .collect();

    if components.first() == Some(&"/") {
        components.remove(0);
    }

    if components.is_empty() {
        return prefix.trim_end_matches('/').to_string();
    }

    if components.len() == 1 {
        return format!("{}{}", prefix, components[0]);
    }

    let last = components.pop().unwrap();

    if prefix == "/" {
        let first = components.remove(0);
        let shortened_middle = components
            .iter()
            .filter_map(|s| s.chars().next())
            .collect::<String>();

        if shortened_middle.is_empty() {
            format!("/{}/{}", first, last)
        } else {
            format!("/{}/{}/{}", first, shortened_middle, last)
        }
    } else {
        let shortened = components
            .iter()
            .filter_map(|s| s.chars().next())
            .collect::<String>();
        format!("~/{}/{}", shortened, last)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_compute_tab_appearance_shell_in_normal_directory() {
        let config = AppConfig::default();
        let appearance = TabAppearance::compute("zsh", "/foo/bar", 1, "", &config);
        let zsh_proc = config.find_process("zsh").expect("zsh built-in process");
        assert_eq!(appearance.icon, zsh_proc.icon());
        assert_eq!(appearance.colour, "#f3f59d");
        assert_eq!(appearance.name, "bar");
        assert_eq!(appearance.name_formatted, "#[fg=#f3f59d]#[bold]bar#[nobold]");
    }

    #[test]
    fn test_compute_tab_appearance_process_in_normal_directory() {
        let toml_str = r###"
            [[process]]
            names = ["nvim"]
            icon = ""
            colour = "#81c8be"
            static_display_name = "nvim"
        "###;
        let config = AppConfig::parse_from_str(toml_str).expect("Parsed config");
        let appearance = TabAppearance::compute("nvim", "/foo/bar", 1, "", &config);
        assert_eq!(appearance.icon, "");
        assert_eq!(appearance.colour, "#81c8be");
        assert_eq!(appearance.name, "nvim");
        assert_eq!(appearance.name_formatted, "#[fg=#81c8be]#[bold]nvim#[nobold]");
    }

    #[test]
    fn test_compute_tab_appearance_live_template_in_process() {
        let toml_str = r###"
            [[process.rules]]
            names = ["cargo"]
            icon = ""
            colour = "#f38ba8"
            live_display_name = "cargo ({{pwd}})"
        "###;
        let config = AppConfig::parse_from_str(toml_str).expect("Parsed config");
        let appearance = TabAppearance::compute("cargo", "/mnt/storage/work/odyssey", 1, "", &config);
        assert_eq!(appearance.icon, "");
        assert_eq!(appearance.name, "cargo (odyssey)");
    }

    #[test]
    fn test_compute_tab_appearance_in_configured_directory() {
        let toml_str = r###"
            [[directory.rules]]
            path = "/mnt/str/cloud/"
            icon = ""
            colour = "#ea999c"
            display_name_pattern = "^/mnt/str/cloud/[^/]+/([^/]+)"
        "###;
        let config = AppConfig::parse_from_str(toml_str).expect("Parsed config");

        let appearance_shell = TabAppearance::compute("bash", "/mnt/str/cloud/user/odyssey/src", 1, "", &config);
        assert_eq!(appearance_shell.icon, "");
        assert_eq!(appearance_shell.colour, "#ea999c");
        assert_eq!(appearance_shell.name, "odyssey");
        assert_eq!(appearance_shell.name_formatted, "#[fg=#ea999c]#[bold]odyssey#[nobold]");

        let appearance_nvim = TabAppearance::compute("nvim", "/mnt/str/cloud/user/odyssey/src", 1, "", &config);
        assert_eq!(appearance_nvim.icon, config.process.default.icon);
        assert_eq!(appearance_nvim.colour, config.process.default.colour);
        assert_eq!(appearance_nvim.name, "nvim");
    }

    #[test]
    fn test_compute_tab_appearance_process_context() {
        let toml_str = r###"
            [[directory.rules]]
            path = "/mnt/str/cloud/"
            icon = ""
            colour = "#ea999c"
            display_name_pattern = "^/mnt/str/cloud/[^/]+/([^/]+)"
            process_context = true

            [[process.rules]]
            names = ["runner"]
            icon = "󰚩"
            colour = "#f38ba8"
        "###;
        let config = AppConfig::parse_from_str(toml_str).expect("Parsed config");

        let appearance_runner = TabAppearance::compute("runner", "/mnt/str/cloud/user/project-build/src", 1, "", &config);
        assert_eq!(appearance_runner.icon, "󰚩");
        assert_eq!(appearance_runner.colour, "#ea999c");
        assert_eq!(appearance_runner.name, "project-build › runner");
        assert!(appearance_runner.name_formatted.contains("›"));
        assert!(appearance_runner.name_formatted.contains("runner"));
    }

    #[test]
    fn test_compute_tab_appearance_multi_pane_badge() {
        let config = AppConfig::default();
        let appearance = TabAppearance::compute("zsh", "/foo/bar", 3, "", &config);
        let expected_name = format!("bar {} {} 3", config.style.badge_divider.symbol, config.panes.icon);
        assert_eq!(appearance.name, expected_name);
        assert!(appearance.name_formatted.contains(&config.style.badge_divider.symbol));
        assert!(appearance.name_formatted.contains(&config.panes.icon));
    }

    #[test]
    fn test_compute_tab_appearance_pane_title_extraction() {
        let toml_str = r###"
            [[process.rules]]
            names = ["ssh"]
            icon = "󰣀"
            colour = "#ca9ee6"
            display_name_pattern = "ssh\\s+(?:[^@]+@)?([^\\s]+)"
        "###;
        let config = AppConfig::parse_from_str(toml_str).expect("Parsed config");
        let appearance = TabAppearance::compute("ssh", "/foo/bar", 1, "ssh user@dev-server-01", &config);
        assert_eq!(appearance.icon, "󰣀");
        assert_eq!(appearance.name, "dev-server-01");
    }

    #[test]
    fn test_compute_tab_appearance_styles_and_panes_intersection() {
        let toml_str = r###"
            [style.font]
            bold = false
            text_colour = "match_icon"

            [style.process_divider]
            colour = "#9399b2"
            symbol = "::"

            [style.badge_divider]
            colour = "#9399b2"
            symbol = "|"

            [panes]
            enabled = true
            icon = "󰆞"
            colour = "#f38ba8"

            [[directory.rules]]
            path = "/mnt/str/cloud/"
            icon = ""
            colour = "#ea999c"
            display_name_pattern = "^/mnt/str/cloud/[^/]+/([^/]+)"
            process_context = true
            process_tab_format = "{dir} · {proc}"

            [[process.rules]]
            names = ["runner"]
            icon = "󰚩"
            colour = "#caaafe"

            [[process.rules]]
            names = ["nvim"]
            icon = ""
            colour = "#81c8be"
        "###;
        let config = AppConfig::parse_from_str(toml_str).expect("Parsed config");

        let appearance_runner = TabAppearance::compute("runner", "/mnt/str/cloud/user/myproj/src", 2, "", &config);
        assert_eq!(appearance_runner.name, "myproj :: runner | 󰆞 2");
        assert!(appearance_runner.name_formatted.contains("#[fg=#ea999c]myproj"));
        assert!(appearance_runner.name_formatted.contains("#[fg=#caaafe]󰚩 #[fg=#caaafe]runner"));
        assert!(appearance_runner.name_formatted.contains("#[fg=#9399b2]| #[fg=#f38ba8]󰆞 #[fg=#f38ba8]#[bold]2#[nobold]"));

        let appearance_nvim = TabAppearance::compute("nvim", "/foo/bar", 1, "", &config);
        assert_eq!(appearance_nvim.name_formatted, "#[fg=#81c8be]nvim");
    }

    #[test]
    fn test_compute_tab_appearance_panes_enabled_false() {
        let toml_str = r###"
            [panes]
            enabled = false
        "###;
        let config = AppConfig::parse_from_str(toml_str).expect("Parsed config");
        let appearance = TabAppearance::compute("zsh", "/foo/bar", 4, "", &config);
        assert_eq!(appearance.name, "bar");
        assert!(!appearance.name_formatted.contains("󰤼"));
    }

    #[test]
    fn test_compute_tab_appearance_display_name_override() {
        let toml_str = r###"
            [[process.rules]]
            names = ["mytool", "mytool-cli", "runner"]
            icon = ""
            colour = "#4A9A4C"
            static_display_name = "mytool"
        "###;
        let config = AppConfig::parse_from_str(toml_str).expect("Parsed config");
        let appearance_cli = TabAppearance::compute("mytool-cli", "/foo/bar", 1, "", &config);
        assert_eq!(appearance_cli.icon, "");
        assert_eq!(appearance_cli.name, "mytool");

        let appearance_runner = TabAppearance::compute("runner", "/foo/bar", 1, "", &config);
        assert_eq!(appearance_runner.name, "mytool");
    }

    #[test]
    fn test_compute_universal_root_directory_and_ignored_shell() {
        let toml_str = r###"
            [[directory.rules]]
            path = "/"
            icon = ""
            colour = "#f3f59d"
            live_display_name = "{{pwd}}"
            process_context = true

            [[directory.rules]]
            path = "/mnt/storage/work/"
            icon = ""
            colour = "#ea999c"
            process_context = true

            [[process.rules]]
            names = ["zsh", "bash"]
            icon = ""
            ignored = true

            [[process.rules]]
            names = ["nvim"]
            icon = ""
            colour = "#81c8be"
        "###;
        let config = AppConfig::parse_from_str(toml_str).expect("Parsed config");

        // 1. In /mnt/storage/work/odyssey sitting at zsh (ignored):
        // Most specific directory matches (/mnt/storage/work/) and renders directory itself.
        let appearance_work_idle = TabAppearance::compute("zsh", "/mnt/storage/work/odyssey", 1, "", &config);
        assert_eq!(appearance_work_idle.name, "odyssey");
        assert_eq!(appearance_work_idle.icon, "");
        assert_eq!(appearance_work_idle.colour, "#ea999c");

        // 2. In /foo/bar sitting at zsh (ignored):
        // Falls back to universal root directory (/) and renders bar.
        let appearance_root_idle = TabAppearance::compute("zsh", "/foo/bar", 1, "", &config);
        assert_eq!(appearance_root_idle.name, "bar");
        assert_eq!(appearance_root_idle.icon, "");
        assert_eq!(appearance_root_idle.colour, "#f3f59d");

        // 3. In /foo/bar running nvim with process_context = true on /:
        // Universal root directory applies process_context universally across all paths!
        let appearance_root_active = TabAppearance::compute("nvim", "/foo/bar", 1, "", &config);
        assert_eq!(appearance_root_active.name, "bar › nvim");
    }

    #[test]
    fn test_compute_home_directory_exact_without_context() {
        if let Some(home) = dirs::home_dir() {
            let toml_str = r###"
                [[directory.rules]]
                path = "/"
                icon = ""
                colour = "#f3f59d"
                live_display_name = "{{pwd}}"
                process_context = true

                [[directory.rules]]
                path = "~"
                exact = true
                icon = ""
                colour = "#f3f59d"
                live_display_name = "{{pwd}}"
                process_context = false

                [[process.rules]]
                names = ["cli"]
                icon = "󰚩"
                colour = "#caaafe"

                [[process.rules]]
                names = ["zsh"]
                icon = ""
                ignored = true
            "###;
            let config = AppConfig::parse_from_str(toml_str).expect("Parsed config");
            let home_str = home.to_str().unwrap();

            // 1. Sitting idle in ~ -> shows ~
            let appearance_idle = TabAppearance::compute("zsh", home_str, 1, "", &config);
            assert_eq!(appearance_idle.name, "~");
            assert_eq!(appearance_idle.icon, "");

            // 2. Running cli in ~ -> shows cli (no ~ › cli!)
            let appearance_active_home = TabAppearance::compute("cli", home_str, 1, "", &config);
            assert_eq!(appearance_active_home.name, "cli");
            assert_eq!(appearance_active_home.icon, "󰚩");
            assert_eq!(appearance_active_home.colour, "#caaafe");

            // 3. Running cli in ~/projects/foo -> shows foo › cli
            let subdir = home.join("projects").join("foo");
            let appearance_active_subdir = TabAppearance::compute("cli", subdir.to_str().unwrap(), 1, "", &config);
            assert_eq!(appearance_active_subdir.name, "foo › cli");
        }
    }

    #[test]
    fn test_compute_tab_appearance_panes_inherit_left_comprehensive() {
        let toml_str = r###"
            [style.font]
            bold = true
            text_colour = "match_icon"

            [style.badge_divider]
            symbol = "│"
            colour = "#a6adc8"

            [panes]
            enabled = true
            icon = "󰆞"
            colour = "match_left"

            [[directory.rules]]
            path = "/google/src/cloud/slyo/ctxm-rebuild/google3/"
            icon = ""
            colour = "#ea999c"
            static_display_name = "ctxm-rebuild"
            process_context = false

            [[directory.rules]]
            path = "/home/slyo/dotfiles/"
            icon = ""
            colour = "#f3f59d"
            static_display_name = "dotfiles"
            process_context = true

            [[process.rules]]
            names = ["zsh"]
            icon = ""
            ignored = true

            [[process.rules]]
            names = ["nvim"]
            icon = ""
            colour = "#81c8be"

            [[process.rules]]
            names = ["ssh"]
            icon = "󰣀"
            colour = "#ca9ee6"
        "###;
        let config = AppConfig::parse_from_str(toml_str).expect("Parsed config");

        // 1. DirectoryOnly (ctxm-rebuild, red #ea999c): badge must inherit red (#ea999c)
        let app_ctxm = TabAppearance::compute("zsh", "/google/src/cloud/slyo/ctxm-rebuild/google3/", 2, "", &config);
        assert_eq!(app_ctxm.name, "ctxm-rebuild │ 󰆞 2");
        assert!(app_ctxm.name_formatted.contains("#[fg=#ea999c]#[bold]ctxm-rebuild#[nobold]"));
        assert!(app_ctxm.name_formatted.contains("#[fg=#ea999c]󰆞 #[fg=#ea999c]#[bold]2#[nobold]"));

        // 2. DirectoryOnly (dotfiles, yellow #f3f59d): badge must inherit yellow (#f3f59d)
        let app_dotfiles = TabAppearance::compute("zsh", "/home/slyo/dotfiles/", 2, "", &config);
        assert_eq!(app_dotfiles.name, "dotfiles │ 󰆞 2");
        assert!(app_dotfiles.name_formatted.contains("#[fg=#f3f59d]#[bold]dotfiles#[nobold]"));
        assert!(app_dotfiles.name_formatted.contains("#[fg=#f3f59d]󰆞 #[fg=#f3f59d]#[bold]2#[nobold]"));

        // 3. CombinedContext (dotfiles › nvim): left is nvim (#81c8be green), NOT dotfiles (#f3f59d yellow)
        // Badge must inherit green (#81c8be) from immediate most left segment (`nvim`)
        let app_nvim = TabAppearance::compute("nvim", "/home/slyo/dotfiles/", 2, "", &config);
        assert_eq!(app_nvim.name, "dotfiles › nvim │ 󰆞 2");
        assert!(app_nvim.name_formatted.contains("#[fg=#f3f59d]#[bold]dotfiles#[nobold]"));
        assert!(app_nvim.name_formatted.contains("#[fg=#81c8be] #[fg=#81c8be]#[bold]nvim#[nobold]"));
        assert!(app_nvim.name_formatted.contains("#[fg=#81c8be]󰆞 #[fg=#81c8be]#[bold]2#[nobold]"));

        // 4. ProcessOnly (ssh #ca9ee6 mauve in unconfigured directory): badge must inherit mauve (#ca9ee6)
        let app_ssh = TabAppearance::compute("ssh", "/tmp/unmapped", 3, "", &config);
        assert!(app_ssh.name_formatted.contains("#[fg=#ca9ee6]󰆞 #[fg=#ca9ee6]#[bold]3#[nobold]"));

        // 5. Static pane colour ("#f38ba8") overrides match_left when configured
        let mut config_static = config.clone();
        config_static.panes.colour = "#f38ba8".to_string();
        let app_static = TabAppearance::compute("zsh", "/home/slyo/dotfiles/", 2, "", &config_static);
        assert!(app_static.name_formatted.contains("#[fg=#f38ba8]󰆞 #[fg=#f38ba8]#[bold]2#[nobold]"));
    }
}
