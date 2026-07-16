use crate::bottombar::extension::{Extension, ExtensionContext, ExtensionOutput};
use crate::constants::{colours, icons};
use std::time::{SystemTime, UNIX_EPOCH};

/// Extension that detects active build / test toolchains (`blaze`, `bazel`, `cargo`) running inside the pane.
pub struct BlazeExtension;

impl Extension for BlazeExtension {
    fn name(&self) -> &'static str {
        "blaze"
    }

    fn compute(&self, ctx: &ExtensionContext) -> Option<ExtensionOutput> {
        let pid = ctx.pane_pid?;
        if pid == 0 {
            return None;
        }

        let mut sys = sysinfo::System::new();
        let pids = crate::bottombar::retriever::get_pane_process_tree(pid, &mut sys);

        for target_pid in &pids {
            if *target_pid == sysinfo::Pid::from_u32(pid) {
                continue;
            }
            if let Some(proc_) = sys.process(*target_pid) {
                if matches!(
                    proc_.status(),
                    sysinfo::ProcessStatus::Stop | sysinfo::ProcessStatus::Zombie
                ) {
                    continue;
                }

                let name = proc_.name().to_string_lossy().to_lowercase();
                let tool = if name.contains("blaze") || name.contains("rabbit") {
                    "blaze"
                } else if name == "cargo" {
                    "cargo"
                } else if name == "ninja" {
                    "ninja"
                } else if name == "make" {
                    "make"
                } else {
                    continue;
                };

                let mut action = String::new();
                for arg_os in proc_.cmd() {
                    let arg = arg_os.to_string_lossy().to_lowercase();
                    if matches!(
                        arg.as_str(),
                        "build" | "test" | "run" | "check" | "bench" | "clean" | "coverage" | "mobile-install"
                    ) {
                        action = arg;
                        break;
                    }
                }

                let display_cmd = if action.is_empty() {
                    tool.to_string()
                } else {
                    format!("{} {}", tool, action)
                };

                let start = proc_.start_time();
                let elapsed_str = if start > 0 {
                    let now = SystemTime::now()
                        .duration_since(UNIX_EPOCH)
                        .map(|d| d.as_secs())
                        .unwrap_or(0);
                    if now >= start {
                        let secs = now - start;
                        if secs < 60 {
                            format!(" ({}s)", secs)
                        } else {
                            format!(" ({}m {:02}s)", secs / 60, secs % 60)
                        }
                    } else {
                        String::new()
                    }
                } else {
                    String::new()
                };

                return Some(ExtensionOutput {
                    icon: icons::BUILD.to_string(),
                    colour: colours::MAUVE.to_string(),
                    text: format!("{}{}", display_cmd, elapsed_str),
                });
            }
        }

        None
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::bottombar::extension::test_utils::TestContextBuilder;

    #[test]
    fn test_blaze_extension_returns_none_when_pid_none() {
        let builder = TestContextBuilder::new();
        let ctx = builder.build();
        assert!(BlazeExtension.compute(&ctx).is_none());
    }
}
