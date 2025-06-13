use serde::Deserialize;
use std::collections::HashMap;
use std::fs;

// =====================================================================
// Public Structs
// =====================================================================

/// Represents the processed configuration for a single process.
/// This struct is the final, canonical representation of a process's metadata,
/// used throughout the application after parsing.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ProcessInfo {
    pub icon: String,
    pub colour: String,
}

/// Represents the processed configuration for a single process.
/// This struct is the final, canonical representation of a process's metadata,
/// used throughout the application after parsing.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct DirectoryInfo {
    pub directory: String,
    pub icon_override: String,
    pub icon_colour: String,
}

/// Represents the default values from the TOML file.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Defaults {
    pub default_process_icon: String,
    pub default_process_colour: String,
    pub default_icon: String,
    pub default_icon_colour: String,
}

/// Represents override settings from the TOML file.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Overrides {
    pub override_base_shell: Option<String>,
    pub should_override_base_shell: bool,
}

/// Represents the application's fully parsed and processed configuration.
/// This struct aggregates all process configurations and global settings
/// derived from the TOML file.
pub struct AppConfig {
    pub processes: HashMap<String, ProcessInfo>,
    pub directories: HashMap<String, DirectoryInfo>,
    pub defaults: Defaults,
    pub overrides: Overrides,
}

/// =====================================================================
/// Models
/// =====================================================================

/// Deserialization model for a directory entry when defined as a TOML table.
/// Corresponds to entries such as `[directories.dotfiles]`.
#[derive(Deserialize, Debug)]
struct DirectoryDetails {
    path: String,
    icon: String,
    #[serde(default)]
    colour: Option<String>,
}

/// Deserialization model for a process entry when defined as a TOML table.
/// Corresponds to entries such as `nvim = { default_process_icon = "?", default_process_colour = "#fff" }`.
#[derive(Deserialize, Debug)]
struct ProcessDetails {
    icon: String,
    #[serde(default)]
    colour: Option<String>,
}

/// Deserialization model for a single process configuration entry.
/// This allows a process to be defined either as a simple string (for the default_process_icon)
/// or as a detailed table (`ProcessDetails`).
#[derive(Deserialize, Debug)]
#[serde(untagged)]
enum ProcessConfigEntryValue {
    Icon(String),
    Details(ProcessDetails),
}

/// Deserialization model for the `[config]` section of the TOML file.
/// Captures global settings like default icons and colours.
#[derive(Deserialize, Debug)]
struct ConfigSection {
    #[serde(rename = "default-process-icon")]
    default_process_icon: String,
    #[serde(rename = "default-process-colour")]
    default_process_colour: String,
    #[serde(rename = "default-icon")]
    default_icon: String,
    #[serde(rename = "default-icon-colour")]
    default_icon_colour: String,
    #[serde(rename = "override-base-shell-name")]
    #[serde(default)]
    override_base_shell_name: Option<String>,
}

/// Represents the top-level structure of the `autoname.toml` file.
/// This struct is the primary target for `toml::from_str`, directly mapping
/// to the sections and tables defined in the configuration file.
#[derive(Deserialize, Debug)]
struct AutonameTomlConfig {
    config: ConfigSection,
    #[serde(default)]
    processes: HashMap<String, ProcessConfigEntryValue>,
    #[serde(default)]
    directories: HashMap<String, DirectoryDetails>,
}

/// Parses the `autoname.toml` file and returns an `AppConfig` struct.
pub fn parse_autoname_config() -> Result<AppConfig, String> {
    let home_dir = match dirs::home_dir() {
        Some(dir) => dir,
        None => return Err("Could not find home directory.".to_string()),
    };

    let config_path = home_dir.join(".tmux").join("autoname.toml");

    if !config_path.exists() {
        return Err(format!(
            "Configuration file not found at {:?}",
            config_path
        ));
    }

    let config_content = fs::read_to_string(&config_path)
        .map_err(|e| format!("Failed to read config file {:?}: {}", config_path, e))?;

    let toml_config: AutonameTomlConfig = toml::from_str(&config_content)
        .map_err(|e| format!("Failed to parse TOML from {:?}: {}", config_path, e))?;

    let default_colour = toml_config.config.default_process_colour.clone();
    
    let process_map = toml_config
        .processes
        .into_iter()
        .map(|(name, entry_value)| {
            let (icon, colour) = match entry_value {
                ProcessConfigEntryValue::Icon(icon_str) => (
                    icon_str, 
                    default_colour.clone()
                ),
                ProcessConfigEntryValue::Details(details) => (
                    details.icon,
                    details.colour.unwrap_or_else(|| default_colour.clone()),
                ),
            };
            (name, ProcessInfo { icon, colour })
        })
        .collect();

    let directory_map = toml_config
        .directories
        .into_iter()
        .map(|(name, details)| {
            (
                name,
                DirectoryInfo {
                    directory: details.path,
                    icon_override: details.icon,
                    icon_colour: details.colour.unwrap_or_else(|| default_colour.clone()),
                },
            )
        })
        .collect();

    Ok(AppConfig {
        processes: process_map,
        directories: directory_map,
        defaults: Defaults {
            default_process_icon: toml_config.config.default_process_icon,
            default_process_colour: default_colour,
            default_icon: toml_config.config.default_icon,
            default_icon_colour: toml_config.config.default_icon_colour,
        },
        overrides: Overrides {
            override_base_shell: toml_config.config.override_base_shell_name.clone(),
            should_override_base_shell: toml_config.config.override_base_shell_name.is_some(),
        },
    })
} 