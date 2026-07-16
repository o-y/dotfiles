pub use crate::config::domain::{
    AppConfig, AppearanceRule, DirectoriesConfig, DirectoryInfo, DividerStyle, FontStyle, PanesConfig,
    ProcessDefault, ProcessInfo, ProcessesConfig, StyleConfig, TabNamingRule,
};
use serde::Deserialize;
use std::fs;
use std::path::PathBuf;

// =====================================================================
// Deserialization Models (`[style.font]`, `[style.divider]`, `[panes]`)
// =====================================================================

#[derive(Deserialize, Debug, Clone, Default)]
struct FontStyleSection {
    bold: Option<bool>,
    text_colour: Option<String>,
}

#[derive(Deserialize, Debug, Clone, Default)]
struct DividerStyleSection {
    symbol: Option<String>,
    colour: Option<String>,
}

#[derive(Deserialize, Debug, Clone, Default)]
struct StyleSection {
    #[serde(default)]
    font: FontStyleSection,
    #[serde(default)]
    process_divider: DividerStyleSection,
    #[serde(default)]
    badge_divider: DividerStyleSection,
}

#[derive(Deserialize, Debug, Clone, Default)]
struct PanesSection {
    enabled: Option<bool>,
    icon: Option<String>,
    colour: Option<String>,
}

#[derive(Deserialize, Debug, Clone)]
struct DirectoryDetails {
    path: Option<String>,
    paths: Option<Vec<String>>,
    icon: String,
    colour: Option<String>,
    display_name_pattern: Option<String>,
    static_display_name: Option<String>,
    live_display_name: Option<String>,
    #[serde(default)]
    exact: bool,
    #[serde(default)]
    process_context: bool,
    bold: Option<bool>,
}

#[derive(Deserialize, Debug, Clone)]
struct ProcessDetails {
    names: Vec<String>,
    icon: String,
    colour: Option<String>,
    display_name_pattern: Option<String>,
    static_display_name: Option<String>,
    live_display_name: Option<String>,
    #[serde(default)]
    ignored: bool,
    bold: Option<bool>,
}

#[derive(Deserialize, Debug, Clone, Default)]
struct ProcessDefaultSection {
    icon: Option<String>,
    colour: Option<String>,
}

#[derive(Deserialize, Debug, Clone, Default)]
struct ProcessGroupSection {
    #[serde(default)]
    default: ProcessDefaultSection,
    #[serde(default, alias = "rule", alias = "list")]
    rules: Vec<ProcessDetails>,
}

#[derive(Deserialize, Debug, Clone, Default)]
struct DirectoryGroupSection {
    #[serde(default, alias = "rule", alias = "list")]
    rules: Vec<DirectoryDetails>,
}

#[derive(Deserialize, Debug, Default)]
struct AutonameTomlConfig {
    #[serde(default)]
    style: StyleSection,
    #[serde(default)]
    panes: PanesSection,
    #[serde(default, alias = "processes")]
    process: ProcessGroupSection,
    #[serde(default, alias = "directories")]
    directory: DirectoryGroupSection,
}

impl From<ProcessDefaultSection> for ProcessDefault {
    fn from(s: ProcessDefaultSection) -> Self {
        let def = Self::default();
        Self {
            icon: s.icon.unwrap_or(def.icon),
            colour: s.colour.unwrap_or(def.colour),
        }
    }
}

impl FontStyleSection {
    fn into_font_style(self, fallback: FontStyle) -> FontStyle {
        FontStyle {
            bold: self.bold.unwrap_or(fallback.bold),
            text_colour: self.text_colour.unwrap_or(fallback.text_colour),
        }
    }
}

impl DividerStyleSection {
    fn into_divider_style(self, fallback: DividerStyle) -> DividerStyle {
        DividerStyle {
            symbol: self.symbol.unwrap_or(fallback.symbol),
            colour: self.colour.unwrap_or(fallback.colour),
        }
    }
}

impl From<StyleSection> for StyleConfig {
    fn from(s: StyleSection) -> Self {
        let def = Self::default();
        Self {
            font: s.font.into_font_style(def.font),
            process_divider: s.process_divider.into_divider_style(def.process_divider),
            badge_divider: s.badge_divider.into_divider_style(def.badge_divider),
        }
    }
}

impl From<PanesSection> for PanesConfig {
    fn from(s: PanesSection) -> Self {
        let def = Self::default();
        Self {
            enabled: s.enabled.unwrap_or(def.enabled),
            icon: s.icon.unwrap_or(def.icon),
            colour: s.colour.unwrap_or(def.colour),
        }
    }
}

impl AutonameTomlConfig {
    fn into_app_config(self) -> AppConfig {
        let process_default: ProcessDefault = self.process.default.into();

        let mut processes = AppConfig::default().process.rules;
        for process_group in self.process.rules {
            let colour = process_group
                .colour
                .unwrap_or_else(|| process_default.colour.clone());
            let naming_rule = TabNamingRule::from_options(
                process_group.display_name_pattern.as_ref(),
                process_group.static_display_name.as_ref(),
                process_group.live_display_name.as_ref(),
            );
            for name in process_group.names {
                processes.insert(
                    name,
                    ProcessInfo {
                        appearance: AppearanceRule {
                            icon: process_group.icon.clone(),
                            colour: colour.clone(),
                            naming_rule: naming_rule.clone(),
                            bold: process_group.bold,
                        },
                        ignored: process_group.ignored,
                    },
                );
            }
        }

        let mut directories = Vec::new();
        for details in self.directory.rules {
            let colour = details.colour.unwrap_or_else(|| crate::constants::colours::YELLOW.to_string());
            let mut paths_to_add = details.paths.unwrap_or_default();
            if let Some(p) = details.path {
                paths_to_add.push(p);
            }
            let naming_rule = TabNamingRule::from_options(
                details.display_name_pattern.as_ref(),
                details.static_display_name.as_ref(),
                details.live_display_name.as_ref(),
            );
            for p in paths_to_add {
                if let Some(expanded) = expand_directory(&p) {
                    directories.push(DirectoryInfo {
                        path: expanded,
                        exact: details.exact,
                        appearance: AppearanceRule {
                            icon: details.icon.clone(),
                            colour: colour.clone(),
                            naming_rule: naming_rule.clone(),
                            bold: details.bold,
                        },
                        process_context: details.process_context,
                    });
                }
            }
        }

        if !directories.iter().any(|d| d.path == std::path::Path::new("/"))
            && let Some(root_dir) = AppConfig::default().directory.rules.into_iter().next()
        {
            directories.push(root_dir);
        }

        AppConfig {
            process: ProcessesConfig {
                default: process_default,
                rules: processes,
            },
            directory: DirectoriesConfig {
                rules: directories,
            },
            style: self.style.into(),
            panes: self.panes.into(),
        }
    }
}

fn expand_directory(path: &str) -> Option<PathBuf> {
    if path == "~" || path == "~/" {
        dirs::home_dir()
    } else if let Some(path_without_tilde) = path.strip_prefix("~/") {
        dirs::home_dir().map(|home| home.join(path_without_tilde))
    } else {
        Some(PathBuf::from(path))
    }
}

impl AppConfig {
    /// Loads the configuration from `~/.tmux/autoname.toml`.
    pub fn load() -> Result<Self, String> {
        let home_dir = dirs::home_dir().ok_or_else(|| "Could not find home directory.".to_string())?;
        let config_path = home_dir.join(".tmux").join("autoname.toml");

        if !config_path.exists() {
            return Err(format!("Configuration file not found at {:?}", config_path));
        }

        let config_content = fs::read_to_string(&config_path)
            .map_err(|e| format!("Failed to read config file {:?}: {}", config_path, e))?;

        Self::parse_from_str(&config_content)
    }

    /// Parses configuration from a TOML string.
    pub fn parse_from_str(config_content: &str) -> Result<Self, String> {
        let toml_config: AutonameTomlConfig = toml::from_str(config_content)
            .map_err(|e| format!("Failed to parse TOML: {}", e))?;

        Ok(toml_config.into_app_config())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_empty_config_uses_defaults() {
        let config = AppConfig::parse_from_str("").expect("Should parse empty string with defaults");
        assert_eq!(config, AppConfig::default());
    }

    #[test]
    fn test_parse_decomposed_style_and_panes_schema() {
        let toml_str = r###"
            [process.default]
            icon = ""
            colour = "#8caaee"

            [directory.default]
            process_context = true

            [style.font]
            bold = false
            text_colour = "match_icon"

            [style.process_divider]
            symbol = "::"
            colour = "#9399b2"

            [style.badge_divider]
            symbol = "|"
            colour = "#9399b2"

            [panes]
            enabled = true
            icon = "󰆞"
            colour = "#f38ba8"

            [[directory.rules]]
            path = "/mnt/storage/work/"
            icon = ""
            colour = "#ea999c"
            display_name_pattern = "^/mnt/storage/work/[^/]+/([^/]+)"
            process_context = true
            bold = true

            [[process.rules]]
            names = ["mytool", "mytool-cli", "runner"]
            icon = ""
            colour = "#4A9A4C"
            static_display_name = "mytool"

            [[process.rules]]
            names = ["ssh"]
            icon = "󰣀"
            colour = "#ca9ee6"
            display_name_pattern = "ssh\\s+(?:[^@]+@)?([^\\s]+)"
            bold = false

            [[process.rules]]
            names = ["zsh", "bash"]
            icon = ""
            colour = "#8caaee"
            ignored = true
        "###;
        let config = AppConfig::parse_from_str(toml_str).expect("Should parse decomposed schema");
        assert_eq!(config.style.font.text_colour, "match_icon");
        assert!(!config.style.font.bold);
        assert_eq!(config.style.process_divider.symbol, "::");
        assert_eq!(config.style.process_divider.colour, "#9399b2");
        assert_eq!(config.style.badge_divider.symbol, "|");
        assert_eq!(config.style.badge_divider.colour, "#9399b2");
        assert_eq!(config.panes.icon, "󰆞");
        assert_eq!(config.panes.colour, "#f38ba8");

        let mytool_proc = config.find_process("runner").expect("Found runner process");
        assert_eq!(mytool_proc.appearance.naming_rule, TabNamingRule::Static("mytool".to_string()));

        let zsh_proc = config.find_process("zsh").expect("Found zsh process");
        assert!(zsh_proc.is_ignored());

        let ssh_proc = config.find_process("ssh").expect("Found ssh process");
        assert!(!ssh_proc.bold(&config.style));

        let work_dir = &config.directory.rules[0];
        assert!(work_dir.bold(&config.style));
    }

    #[test]
    fn test_expand_directory_tilde() {
        if let Some(home) = dirs::home_dir() {
            assert_eq!(expand_directory("~"), Some(home.clone()));
            assert_eq!(expand_directory("~/"), Some(home.clone()));
            assert_eq!(expand_directory("~/projects"), Some(home.join("projects")));
        }
    }
}