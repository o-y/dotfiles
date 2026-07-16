use crate::appearance::SegmentSpan;
use crate::constants::{colours, icons};
use std::path::Path;
use std::process::Command;

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum VcsKind {
    Jj,
    Git,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct VcsAppearance {
    pub kind: VcsKind,
    pub icon: String,
    pub colour: String,
    pub branch: String,
    pub formatted: String,
}

impl VcsAppearance {
    pub fn as_span(&self) -> SegmentSpan {
        SegmentSpan::new(&self.branch, &self.colour).with_icon(&self.icon)
    }
}

impl From<&VcsAppearance> for SegmentSpan {
    fn from(vcs: &VcsAppearance) -> Self {
        vcs.as_span()
    }
}

/// A trait for version control system backends that detect repository state and provide appearance metadata.
pub trait VcsProvider {
    fn detect(&self, working_directory: &Path) -> Option<VcsAppearance>;
}

pub struct JjProvider;
pub struct GitProvider;

impl VcsAppearance {
    /// Detects the VCS repository at `working_directory` by querying registered `VcsProvider` backends in order.
    pub fn compute(working_directory: &Path) -> Option<Self> {
        let providers: &[&dyn VcsProvider] = &[&JjProvider, &GitProvider];
        for provider in providers {
            if let Some(appearance) = provider.detect(working_directory) {
                return Some(appearance);
            }
        }
        None
    }
}

impl VcsProvider for JjProvider {
    fn detect(&self, working_directory: &Path) -> Option<VcsAppearance> {
        let branch = detect_jj(working_directory)?;
        let icon = icons::JJ.to_string();
        let colour = colours::MAUVE.to_string();
        let formatted = SegmentSpan::new(&branch, &colour)
            .with_icon(&icon)
            .format_tmux();
        Some(VcsAppearance {
            kind: VcsKind::Jj,
            icon,
            colour,
            branch,
            formatted,
        })
    }
}

impl VcsProvider for GitProvider {
    fn detect(&self, working_directory: &Path) -> Option<VcsAppearance> {
        let branch = detect_git(working_directory)?;
        let icon = icons::GIT.to_string();
        let colour = colours::GREEN.to_string();
        let formatted = SegmentSpan::new(&branch, &colour)
            .with_icon(&icon)
            .format_tmux();
        Some(VcsAppearance {
            kind: VcsKind::Git,
            icon,
            colour,
            branch,
            formatted,
        })
    }
}

// TODO: One day we may be able to use the jj-lib rust crate, rather than fanning out to the CLI...
fn detect_jj(working_directory: &Path) -> Option<String> {
    let output = Command::new("jj")
        .arg("log")
        .arg("--no-graph")
        .arg("--ignore-working-copy")
        .arg("-r")
        .arg("@")
        .arg("-T")
        .arg("concat(if(bookmarks, concat(bookmarks.map(|b| b.name()).join(\", \"), \" (\", change_id.short(4), \")\"), change_id.short(4)), if(conflict, \" !\", if(empty, \"\", \"*\")))")
        .current_dir(working_directory)
        .output()
        .ok()?;

    if output.status.success() {
        let stdout = String::from_utf8_lossy(&output.stdout).trim().to_string();
        if !stdout.is_empty() {
            return Some(stdout);
        }
    }
    None
}

fn detect_git(working_directory: &Path) -> Option<String> {
    let mut branch_name = None;

    let output = Command::new("git")
        .arg("branch")
        .arg("--show-current")
        .current_dir(working_directory)
        .output()
        .ok()?;

    if output.status.success() {
        let stdout = String::from_utf8_lossy(&output.stdout).trim().to_string();
        if !stdout.is_empty() {
            branch_name = Some(stdout);
        }
    }

    if branch_name.is_none() {
        // Fallback for detached HEAD
        let output_head = Command::new("git")
            .arg("rev-parse")
            .arg("--short")
            .arg("HEAD")
            .current_dir(working_directory)
            .output()
            .ok()?;

        if output_head.status.success() {
            let stdout = String::from_utf8_lossy(&output_head.stdout).trim().to_string();
            if !stdout.is_empty() {
                branch_name = Some(format!(":{stdout}"));
            }
        }
    }

    let mut branch = branch_name?;

    // Check for dirty working copy (uncommitted changes or conflicts) right inside git repo
    if let Ok(status_out) = Command::new("git")
        .arg("status")
        .arg("--porcelain")
        .current_dir(working_directory)
        .output()
        && status_out.status.success()
    {
        let status_str = String::from_utf8_lossy(&status_out.stdout);
        if !status_str.trim().is_empty() {
            if status_str
                .lines()
                .any(|line| line.starts_with('U') || (line.len() > 1 && &line[1..2] == "U"))
            {
                branch.push_str(" !");
            } else {
                branch.push('*');
            }
        }
    }

    Some(branch)
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::env;

    #[test]
    fn test_vcs_appearance_in_current_repo() {
        let current_dir = env::current_dir().expect("Current dir exists");
        if let Some(vcs) = VcsAppearance::compute(&current_dir) {
            assert!(matches!(vcs.kind, VcsKind::Jj | VcsKind::Git));
            assert!(!vcs.branch.is_empty());
            assert!(!vcs.formatted.is_empty());
        }
    }

    #[test]
    fn test_vcs_appearance_in_tmp_no_repo() {
        let temp_dir = env::temp_dir();
        let vcs = VcsAppearance::compute(&temp_dir);
        assert!(vcs.is_none());
    }
}
