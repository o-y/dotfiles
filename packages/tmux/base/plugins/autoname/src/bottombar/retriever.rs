use crate::appearance::format_pipeline;
use crate::bottombar::extension::{self, ExtensionContext, ExtensionOutput, GroupOutput};
use crate::constants::{colours, symbols};
use std::collections::HashMap;
use std::path::Path;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct BottombarAppearance {
    pub groups: Vec<GroupOutput>,
    pub icon: String,
    pub colour: String,
    pub formatted: String,
}

impl BottombarAppearance {
    /// Computes the bottom bar appearance by concurrently evaluating all registered groups (`all_groups`).
    pub fn compute(
        pane_pid: Option<u32>,
        working_directory: &str,
        process_name: &str,
    ) -> Option<Self> {
        let env_vars = fetch_pane_env(pane_pid);
        let ctx = ExtensionContext {
            working_dir: Path::new(working_directory),
            process_name,
            pane_pid,
            env_vars: &env_vars,
        };

        let groups = extension::all_groups();
        let active_groups = std::thread::scope(|s| {
            let mut handles = Vec::with_capacity(groups.len());
            for grp in &groups {
                handles.push(s.spawn(move || grp.compute(&ctx)));
            }
            let mut results = Vec::new();
            for handle in handles {
                if let Ok(Some(group_output)) = handle.join() {
                    results.push(group_output);
                }
            }
            results
        });

        if active_groups.is_empty() {
            return None;
        }

        let mut all_outputs = Vec::new();
        for grp in &active_groups {
            all_outputs.extend(grp.outputs.clone());
        }

        let mut appearance = Self::format_outputs(&all_outputs)?;
        appearance.groups = active_groups;
        Some(appearance)
    }

    /// Formats a list of extension outputs into a canonical `BottombarAppearance`.
    pub fn format_outputs(outputs: &[ExtensionOutput]) -> Option<Self> {
        if outputs.is_empty() {
            return None;
        }

        let primary_icon = outputs[0].icon.clone();
        let primary_colour = outputs[0].colour.clone();

        let mut formatted_sections = Vec::with_capacity(outputs.len());
        for output in outputs {
            formatted_sections.push(output.as_span().format_tmux());
        }

        let formatted = format_pipeline(&formatted_sections, symbols::VERTICAL_PIPE, colours::DIVIDER_GREY, None);

        Some(Self {
            groups: Vec::new(),
            icon: primary_icon,
            colour: primary_colour,
            formatted,
        })
    }
}

/// Returns `pane_pid` and all of its descendant PIDs (children, grandchildren, etc.)
/// sorted from parent down to youngest child across the entire process tree.
pub fn get_pane_process_tree(pane_pid: u32, sys: &mut sysinfo::System) -> Vec<sysinfo::Pid> {
    sys.refresh_processes(sysinfo::ProcessesToUpdate::All, true);
    let root = sysinfo::Pid::from_u32(pane_pid);
    let mut tree = vec![root];
    let mut i = 0;
    while i < tree.len() {
        let parent_pid = tree[i];
        for (pid, proc_) in sys.processes() {
            if proc_.parent() == Some(parent_pid) && !tree.contains(pid) {
                tree.push(*pid);
            }
        }
        i += 1;
    }
    tree
}

/// Retrieves environment variables from `#{pane_pid}` AND all of its descendant child processes
/// (`/proc/<pid>/environ` and `sysinfo`), merging younger child variables over parent variables.
pub fn fetch_pane_env(pane_pid: Option<u32>) -> HashMap<String, String> {
    let mut env_map = HashMap::new();
    let Some(pid) = pane_pid else {
        return env_map;
    };
    if pid == 0 {
        return env_map;
    }

    let mut sys = sysinfo::System::new();
    let pids = get_pane_process_tree(pid, &mut sys);

    for target_pid in pids {
        let raw_pid = target_pid.as_u32();
        let environ_path = format!("/proc/{}/environ", raw_pid);
        let mut found_proc = false;
        if let Ok(bytes) = std::fs::read(&environ_path) {
            for entry in bytes.split(|&b| b == 0) {
                if let Ok(entry_str) = std::str::from_utf8(entry)
                    && let Some((k, v)) = entry_str.split_once('=')
                {
                    env_map.insert(k.to_string(), v.to_string());
                    found_proc = true;
                }
            }
        }

        if !found_proc
            && let Some(process) = sys.process(target_pid)
        {
            for entry in process.environ() {
                if let Some(entry_str) = entry.to_str()
                    && let Some((k, v)) = entry_str.split_once('=')
                {
                    env_map.insert(k.to_string(), v.to_string());
                }
            }
        }
    }

    env_map
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_format_outputs_returns_none_when_empty() {
        assert!(BottombarAppearance::format_outputs(&[]).is_none());
    }

    #[test]
    fn test_format_outputs_single_extension() {
        let outputs = vec![ExtensionOutput {
            icon: "󰌠".to_string(),
            colour: colours::YELLOW.to_string(),
            text: "jetski-env".to_string(),
        }];

        let appearance = BottombarAppearance::format_outputs(&outputs)
            .expect("Should format single output");
        assert_eq!(appearance.icon, "󰌠");
        assert_eq!(appearance.colour, colours::YELLOW);
        assert_eq!(
            appearance.formatted,
            format!(
                "#[fg={colour}]󰌠 #[fg={subtext}]jetski-env",
                colour = colours::YELLOW,
                subtext = colours::VCS_SUBTEXT
            )
        );
    }

    #[test]
    fn test_format_outputs_multiple_extensions_joined_with_pipe() {
        let outputs = vec![
            ExtensionOutput {
                icon: "󰌠".to_string(),
                colour: colours::YELLOW.to_string(),
                text: "my-venv".to_string(),
            },
            ExtensionOutput {
                icon: "󱃾".to_string(),
                colour: colours::BLUE.to_string(),
                text: "prod-cluster".to_string(),
            },
        ];

        let appearance = BottombarAppearance::format_outputs(&outputs)
            .expect("Should format multiple outputs");
        assert_eq!(appearance.icon, "󰌠");
        assert_eq!(
            appearance.formatted,
            format!(
                "#[fg={yellow}]󰌠 #[fg={subtext}]my-venv #[fg={divider}]│ #[fg={blue}]󱃾 #[fg={subtext}]prod-cluster",
                yellow = colours::YELLOW,
                blue = colours::BLUE,
                subtext = colours::VCS_SUBTEXT,
                divider = colours::DIVIDER_GREY
            )
        );
    }

    #[test]
    fn test_fetch_pane_env_zero_pid() {
        let map = fetch_pane_env(Some(0));
        assert!(map.is_empty());
    }

    #[test]
    fn test_fetch_pane_env_none_pid() {
        let map = fetch_pane_env(None);
        assert!(map.is_empty());
    }
}
