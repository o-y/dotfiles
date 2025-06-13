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
    pub extract_tab_name: Option<String>,
}

/// Represents the default values from the TOML file.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Defaults {
    pub process_icon: String,
    pub process_colour: String,
}

/// Represents override settings from the TOML file.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ShellOverride {
    pub shell_name: String,
    pub icon: String,
    pub colour: String,
}

/// Represents the application's fully parsed and processed configuration.
/// This struct aggregates all process configurations and global settings
/// derived from the TOML file.
pub struct AppConfig {
    pub processes: HashMap<String, ProcessInfo>,
    pub directories: HashMap<String, DirectoryInfo>,
    pub defaults: Defaults,
    pub shell_override: Option<ShellOverride>,
}

/// =====================================================================
/// Models
/// =====================================================================

/// Deserialization model for a single directory entry defined within the TOML config.
#[derive(Deserialize, Debug)]
struct DirectoryDetails {
    path: String,
    icon: String,
    #[serde(default)]
    colour: Option<String>,
    #[serde(default)]
    extract_tab_name: Option<String>,
}

/// Deserialization model for a single process entry defined within the TOML config.
#[derive(Deserialize, Debug)]
struct ProcessDetails {
    names: Vec<String>,
    icon: String,
    #[serde(default)]
    colour: Option<String>,
}

/// Deserialization model for the `[defaults]` section in the TOML file.
#[derive(Deserialize, Debug)]
struct DefaultsSection {
    process_icon: String,
    process_colour: String,
}

/// Deserialization model for the `[shell_override]` section in the TOML file.
#[derive(Deserialize, Debug)]
struct ShellOverrideSection {
    enabled: bool,
    shell_name: String,
    icon: String,
    colour: String,
}

/// Represents the top-level structure of the TOML file.
#[derive(Deserialize, Debug)]
struct AutonameTomlConfig {
    defaults: DefaultsSection,
    #[serde(default)]
    shell_override: Option<ShellOverrideSection>,
    #[serde(default)]
    process: Vec<ProcessDetails>,
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

    let default_colour = toml_config.defaults.process_colour.clone();
    
    let mut process_map = HashMap::new();
    for process_group in toml_config.process {
        let colour = process_group
            .colour
            .unwrap_or_else(|| default_colour.clone());
        for name in process_group.names {
            process_map.insert(
                name,
                ProcessInfo {
                    icon: process_group.icon.clone(),
                    colour: colour.clone(),
                },
            );
        }
    }

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
                    extract_tab_name: details.extract_tab_name,
                },
            )
        })
        .collect();

    let shell_override = toml_config
        .shell_override
        .and_then(|override_config| {
            if override_config.enabled {
                Some(ShellOverride {
                    shell_name: override_config.shell_name,
                    icon: override_config.icon,
                    colour: override_config.colour,
                })
            } else {
                None
            }
        });

    Ok(AppConfig {
        processes: process_map,
        directories: directory_map,
        defaults: Defaults {
            process_icon: toml_config.defaults.process_icon,
            process_colour: default_colour,
        },
        shell_override,
    })
} 