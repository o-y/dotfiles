use crate::bottombar::retriever::BottombarAppearance;
use crate::constants::{colours, icons, texts, tmux};
use crate::RetrieveTarget;

/// Renders output for bottombar targets (`BottombarFormatted`, `BottombarPill`).
pub fn render(
    target: RetrieveTarget,
    pane_pid: Option<u32>,
    working_directory: &str,
    process_name: &str,
) -> String {
    match BottombarAppearance::compute(pane_pid, working_directory, process_name) {
        Some(appearance) => match target {
            RetrieveTarget::BottombarFormatted => appearance.formatted,
            RetrieveTarget::BottombarPill => {
                if appearance.groups.is_empty() {
                    format!(
                        " ─ {}#[fg={}] ─ ",
                        tmux::format_pill(
                            tmux::STATUS_BG,
                            tmux::TERMINAL_BG,
                            tmux::STATUS_BG,
                            tmux::STATUS_SEP_LEFT,
                            &appearance.formatted,
                            tmux::STATUS_SEP_RIGHT,
                        ),
                        tmux::PANE_INACTIVE_BORDER
                    )
                } else {
                    let mut pill_strings = Vec::with_capacity(appearance.groups.len());
                    for group_out in &appearance.groups {
                        let inner_parts: Vec<String> = group_out
                            .outputs
                            .iter()
                            .map(|out| {
                                format!(
                                    "#[fg={colour}]{icon} #[fg={subtext}]{text}",
                                    colour = out.colour,
                                    icon = out.icon,
                                    subtext = colours::VCS_SUBTEXT,
                                    text = out.text
                                )
                            })
                            .collect();
                        let group_inner = inner_parts.join(&format!(
                            " #[fg={divider_colour}]{divider} ",
                            divider_colour = colours::DIVIDER_GREY,
                            divider = crate::constants::symbols::VERTICAL_PIPE
                        ));
                        pill_strings.push(tmux::format_pill(
                            tmux::STATUS_BG,
                            tmux::TERMINAL_BG,
                            tmux::STATUS_BG,
                            tmux::STATUS_SEP_LEFT,
                            &group_inner,
                            tmux::STATUS_SEP_RIGHT,
                        ));
                    }
                    let separator = format!("#[fg={}] ─ ", tmux::PANE_INACTIVE_BORDER);
                    format!(
                        " ─ {}#[fg={}] ─ ",
                        pill_strings.join(&separator),
                        tmux::PANE_INACTIVE_BORDER
                    )
                }
            }
            _ => unreachable!(),
        },
        None => String::new(),
    }
}

/// Renders fallback error/empty output for bottombar targets.
pub fn render_error(target: RetrieveTarget) -> String {
    let err_formatted = format!(
        "#[fg={colour}]{icon} #[fg={subtext}]{text}",
        colour = colours::ERROR,
        icon = icons::ERROR,
        subtext = colours::VCS_SUBTEXT,
        text = texts::NA
    );
    match target {
        RetrieveTarget::BottombarFormatted => err_formatted,
        RetrieveTarget::BottombarPill => format!(
            " ─ {}#[fg={}] ─ ",
            tmux::format_pill(
                tmux::STATUS_BG,
                tmux::TERMINAL_BG,
                tmux::STATUS_BG,
                tmux::STATUS_SEP_LEFT,
                &err_formatted,
                tmux::STATUS_SEP_RIGHT,
            ),
            tmux::PANE_INACTIVE_BORDER
        ),
        _ => unreachable!(),
    }
}
