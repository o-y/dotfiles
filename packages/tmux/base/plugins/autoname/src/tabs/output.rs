use crate::config::domain::AppConfig;
use crate::constants::{colours, icons, texts, tmux};
use crate::RetrieveTarget;

/// Renders output for Tab targets (`TabIcon`, `TabName`, `TabColour`, `TabFormatted`, `TabPillActive`, `TabPillInactive`).
pub fn render(
    target: RetrieveTarget,
    process_name: &str,
    working_directory: &str,
    pane_count: u8,
    pane_title: &str,
    config: &AppConfig,
) -> String {
    let appearance = crate::tabs::retriever::TabAppearance::compute(
        process_name,
        working_directory,
        pane_count,
        pane_title,
        config,
    );

    match target {
        RetrieveTarget::TabIcon => format!("{} ", appearance.icon),
        RetrieveTarget::TabName => appearance.name,
        RetrieveTarget::TabColour => appearance.colour,
        RetrieveTarget::TabFormatted => {
            format_inner(&appearance.colour, &appearance.icon, &appearance.name_formatted)
        }
        RetrieveTarget::TabPillActive => {
            let inner =
                format_inner(&appearance.colour, &appearance.icon, &appearance.name_formatted);
            tmux::format_pill(
                tmux::WINDOW_ACTIVE_COLOUR,
                tmux::TERMINAL_BG,
                tmux::WINDOW_ACTIVE_COLOUR,
                tmux::WINDOW_SEP_LEFT,
                &inner,
                tmux::WINDOW_SEP_RIGHT,
            )
        }
        RetrieveTarget::TabPillInactive => {
            let inner =
                format_inner(&appearance.colour, &appearance.icon, &appearance.name_formatted);
            tmux::format_pill(
                tmux::WINDOW_INACTIVE_COLOUR,
                tmux::TERMINAL_BG,
                tmux::WINDOW_INACTIVE_COLOUR,
                tmux::WINDOW_SEP_LEFT,
                &inner,
                tmux::WINDOW_SEP_RIGHT,
            )
        }
        _ => unreachable!(),
    }
}

/// Renders fallback error/empty output for Tab targets.
pub fn render_error(target: RetrieveTarget) -> String {
    let err_formatted = format_inner(colours::ERROR, icons::ERROR, texts::NA);
    match target {
        RetrieveTarget::TabIcon => format!("{} ", icons::ERROR),
        RetrieveTarget::TabName => texts::NA.to_string(),
        RetrieveTarget::TabColour => colours::ERROR.to_string(),
        RetrieveTarget::TabFormatted => err_formatted.clone(),
        RetrieveTarget::TabPillActive => tmux::format_pill(
            tmux::WINDOW_ACTIVE_COLOUR,
            tmux::TERMINAL_BG,
            tmux::WINDOW_ACTIVE_COLOUR,
            tmux::WINDOW_SEP_LEFT,
            &err_formatted,
            tmux::WINDOW_SEP_RIGHT,
        ),
        RetrieveTarget::TabPillInactive => tmux::format_pill(
            tmux::WINDOW_INACTIVE_COLOUR,
            tmux::TERMINAL_BG,
            tmux::WINDOW_INACTIVE_COLOUR,
            tmux::WINDOW_SEP_LEFT,
            &err_formatted,
            tmux::WINDOW_SEP_RIGHT,
        ),
        _ => unreachable!(),
    }
}

fn format_inner(colour: &str, icon: &str, text: &str) -> String {
    format!(
        "#[fg={colour}]{icon} #[fg={subtext}]{text}",
        colour = colour,
        icon = icon,
        subtext = colours::VCS_SUBTEXT,
        text = text
    )
}
