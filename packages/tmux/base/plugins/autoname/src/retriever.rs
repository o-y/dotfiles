use crate::parser::AppConfig;
use dirs;
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
///     - If the running process is the configured `override_base_shell` (e.g., "zsh"),
///       the tab name is the formatted directory name.
///     - Otherwise, the tab name is the process name.
///
/// 2.  If the `working_directory` is not in a configured directory:
///     - If the running process is the `override_base_shell`:
///         - The icon and colour are the `default_icon` and `default_icon_colour`.
///         - The tab name is the formatted directory name.
///     - Otherwise (for any other process):
///         - The appearance is looked up from the `[processes]` configuration.
///         - If not found, it falls back to `default_process_icon` and `default_process_colour`.
///         - The tab name is always the process name.
pub fn compute_tab_appearance(
    process_name: &str,
    working_directory: &str,
    app_config: &AppConfig,
) -> TabAppearance {
    let is_base_shell = app_config.overrides.should_override_base_shell
        && app_config.overrides.override_base_shell.as_deref() == Some(process_name);

    // Check if we are in a configured directory
    if let Some(dir_appearance) = get_appearance_for_directory(working_directory, app_config) {
        if is_base_shell {
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
        if is_base_shell {
            TabAppearance {
                icon: app_config.defaults.default_icon.clone(),
                colour: app_config.defaults.default_icon_colour.clone(),
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
                        icon: app_config.defaults.default_process_icon.clone(),
                        colour: app_config.defaults.default_process_colour.clone(),
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
                return Some(TabAppearance {
                    icon: dir_info.icon_override.clone(),
                    colour: dir_info.icon_colour.clone(),
                    name: format_directory_path(&configured_dir),
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