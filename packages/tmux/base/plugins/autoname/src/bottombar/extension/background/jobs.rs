use crate::bottombar::extension::{Extension, ExtensionContext, ExtensionOutput};
use crate::constants::{colours, icons};

/// Extension that detects suspended / stopped (`Ctrl+Z`) processes inside the active pane.
pub struct JobsExtension;

impl Extension for JobsExtension {
    fn name(&self) -> &'static str {
        "jobs"
    }

    fn compute(&self, ctx: &ExtensionContext) -> Option<ExtensionOutput> {
        let pid = ctx.pane_pid?;
        if pid == 0 {
            return None;
        }

        let mut sys = sysinfo::System::new();
        let pids = crate::bottombar::retriever::get_pane_process_tree(pid, &mut sys);

        let mut stopped_names = Vec::new();
        for target_pid in &pids {
            if *target_pid == sysinfo::Pid::from_u32(pid) {
                continue; // Skip the root login shell itself
            }
            if let Some(proc_) = sys.process(*target_pid)
                && matches!(proc_.status(), sysinfo::ProcessStatus::Stop)
            {
                let name = proc_.name().to_string_lossy().to_string();
                if !stopped_names.contains(&name) {
                    stopped_names.push(name);
                }
            }
        }

        if stopped_names.is_empty() {
            return None;
        }

        let text = if stopped_names.len() == 1 {
            stopped_names[0].clone()
        } else {
            format!("{} stopped", stopped_names.len())
        };

        Some(ExtensionOutput {
            icon: icons::JOB.to_string(),
            colour: colours::PEACH.to_string(),
            text,
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::bottombar::extension::test_utils::TestContextBuilder;

    #[test]
    fn test_jobs_extension_returns_none_when_pid_none() {
        let builder = TestContextBuilder::new();
        let ctx = builder.build();
        assert!(JobsExtension.compute(&ctx).is_none());
    }
}
