use crate::constants::{colours, icons, texts, tmux};
use crate::RetrieveTarget;
use std::path::Path;

/// Renders output for VCS targets (`VcsIcon`, `VcsBranch`, `VcsColour`, `VcsFormatted`, `VcsPill`).
pub fn render(target: RetrieveTarget, working_directory: &str) -> String {
    match crate::vcs::VcsAppearance::compute(Path::new(working_directory)) {
        Some(appearance) => match target {
            RetrieveTarget::VcsIcon => format!("{} ", appearance.icon),
            RetrieveTarget::VcsBranch => appearance.branch,
            RetrieveTarget::VcsColour => appearance.colour,
            RetrieveTarget::VcsFormatted => appearance.formatted,
            RetrieveTarget::VcsPill => {
                let pill = tmux::format_pill(
                    tmux::STATUS_BG,
                    tmux::TERMINAL_BG,
                    tmux::STATUS_BG,
                    tmux::STATUS_SEP_LEFT,
                    &appearance.formatted,
                    tmux::STATUS_SEP_RIGHT,
                );
                format!(" {pill}")
            }
            _ => unreachable!(),
        },
        None => render_error(target),
    }
}

/// Renders fallback error/empty output for VCS targets.
pub fn render_error(target: RetrieveTarget) -> String {
    match target {
        RetrieveTarget::VcsIcon => format!("{} ", icons::ERROR),
        RetrieveTarget::VcsBranch => texts::NA.to_string(),
        RetrieveTarget::VcsColour => colours::ERROR.to_string(),
        RetrieveTarget::VcsFormatted | RetrieveTarget::VcsPill => String::new(),
        _ => unreachable!(),
    }
}
