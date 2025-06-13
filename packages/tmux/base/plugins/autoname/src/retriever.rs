use crate::parser::AppConfig;
use dirs;
use regex::Regex;
use std::path::Path;
use std::path::PathBuf;

/// Defines the final, canonical representation of a process's metadata,
/// used throughout the application after parsing.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct TabAppearance {
    pub icon: String,
    pub colour: String,
    pub name: String,
}

/// Computes the tab appearance based on the process name and working directory.
///
/// The logic for determining the appearance follows these rules:
///
/// 1.  **Configured Directory**: If the `working_directory` is within a path
///     defined in the `[directories]` section of the configuration:
///     - The icon and colour are taken from the directory's configuration.
///     - If the `shell_override` is active for the current `process_name`,
///       the tab name is the formatted directory name.
///     - Otherwise, the tab name is the process name.
///
/// 2.  If the `working_directory` is not in a configured directory:
///     - If the `shell_override` is active:
///         - The icon and colour are from the `[shell_override]` config.
///         - The tab name is the formatted directory name.
///     - Otherwise (for any other process):
///         - The appearance is looked up from the `[processes]` configuration.
///         - If not found, it falls back to the `[defaults]` configuration.
///         - The tab name is always the process name.
pub fn compute_tab_appearance(
    process_name: &str,
    working_directory: &str,
    app_config: &AppConfig,
) -> TabAppearance {
    let is_shell_override = app_config
        .shell_override
        .as_ref()
        .map_or(false, |so| so.shell_name == process_name);

    // Check if we are in a configured directory
    if let Some(dir_appearance) = get_appearance_for_directory(working_directory, app_config) {
        if is_shell_override {
            // Use directory appearance but with directory name
            dir_appearance
        } else {
            // Use directory appearance but with process name
            TabAppearance {
                name: process_name.to_string(),
                ..dir_appearance
            }
        }
    } else {
        // We are in a non-registered directory
        if is_shell_override {
            // This should be safe to unwrap due to the is_shell_override check
            let override_info = app_config.shell_override.as_ref().unwrap();
            TabAppearance {
                icon: override_info.icon.clone(),
                colour: override_info.colour.clone(),
                name: format_directory_path(Path::new(working_directory)),
            }
        } else {
            // Look for a specific process configuration
            app_config
                .processes
                .get(process_name)
                .map(|info| TabAppearance {
                    icon: info.icon.clone(),
                    colour: info.colour.clone(),
                    name: process_name.to_string(),
                })
                .unwrap_or_else(|| {
                    // Fallback to default process appearance
                    TabAppearance {
                        icon: app_config.defaults.process_icon.clone(),
                        colour: app_config.defaults.process_colour.clone(),
                        name: process_name.to_string(),
                    }
                })
        }
    }
}

/// Checks if the working directory matches any of the configured directories.
///
/// This function iterates through the `directories` in the `AppConfig` and checks
/// if the `working_directory` is a sub-path of them. If a match is found,
/// it returns a `TabAppearance` with the directory's configured icon, colour,
/// and formatted name.
fn get_appearance_for_directory(
    working_directory: &str,
    app_config: &AppConfig,
) -> Option<TabAppearance> {
    let working_dir_path = Path::new(working_directory);

    for (_name, dir_info) in &app_config.directories {
        if let Some(configured_dir) = expand_directory(&dir_info.directory) {
            if working_dir_path.starts_with(&configured_dir) {
                let name = if let Some(re_str) = &dir_info.extract_tab_name {
                    Regex::new(re_str)
                        .ok()
                        .and_then(|re| {
                            re.captures(working_dir_path.to_str().unwrap_or(""))
                                .and_then(|caps| {
                                    caps.get(1)
                                        .or(caps.get(0))
                                        .map(|m| m.as_str().to_string())
                                })
                        })
                        .unwrap_or_else(|| format_directory_path(&working_dir_path))
                } else {
                    format_directory_path(&working_dir_path)
                };

                return Some(TabAppearance {
                    icon: dir_info.icon_override.clone(),
                    colour: dir_info.icon_colour.clone(),
                    name,
                });
            }
        }
    }

    None
}

/// Expands a directory path that may start with `~`.
///
/// This function takes a path string that may begin with `~` (e.g., `~/some/dir`).
/// If it does, `~` is replaced with the user's home directory. If the path does
/// not start with `~`, it is treated as a regular path.
///
/// Returns `None` if the path starts with `~` but the home directory cannot be
/// resolved. Otherwise, returns `Some(PathBuf)` with the expanded path.
fn expand_directory(path: &str) -> Option<PathBuf> {
    if let Some(path_without_tilde) = path.strip_prefix("~/") {
        dirs::home_dir().map(|home| home.join(path_without_tilde))
    } else {
        Some(PathBuf::from(path))
    }
}

/// Formats a directory path for display.
///
/// Returns "~" for the home directory, or the final component for other paths.
/// For example, `/foo/bar/baz` becomes `baz`.
fn format_directory_path(path: &Path) -> String {
    if let Some(home_dir) = dirs::home_dir() {
        if path == home_dir {
            return "~".to_string();
        }
    }

    path.file_name()
        .and_then(|name| name.to_str())
        .map(String::from)
        .unwrap_or_else(|| path.to_string_lossy().to_string())
}