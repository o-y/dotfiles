use crate::constants::colours;

/// A single visual segment (span) containing optional icon, text, and styling metadata.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SegmentSpan {
    pub text: String,
    pub icon: Option<String>,
    pub colour: String,
    pub text_colour: Option<String>,
    pub bold: bool,
}

impl SegmentSpan {
    pub fn new(text: impl Into<String>, colour: impl Into<String>) -> Self {
        Self {
            text: text.into(),
            icon: None,
            colour: colour.into(),
            text_colour: None,
            bold: false,
        }
    }

    pub fn with_icon(mut self, icon: impl Into<String>) -> Self {
        self.icon = Some(icon.into());
        self
    }

    pub fn with_text_colour(mut self, col: impl Into<String>) -> Self {
        self.text_colour = Some(col.into());
        self
    }

    pub fn with_bold(mut self, bold: bool) -> Self {
        self.bold = bold;
        self
    }

    /// Formats the span into a standard tmux styled section (`#[fg=colour]{icon} #[fg=text_colour]{text}`).
    pub fn format_tmux(&self) -> String {
        let text_col = self.text_colour.as_deref().unwrap_or(colours::VCS_SUBTEXT);
        let text_part = format_text(&self.text, Some(text_col), self.bold);
        match &self.icon {
            Some(icon) if !icon.is_empty() => {
                format!("#[fg={colour}]{icon} {text_part}", colour = self.colour, icon = icon, text_part = text_part)
            }
            _ => text_part,
        }
    }
}

/// A buffer representing an ordered sequence of visual segments (`SegmentSpan`).
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct SegmentBuffer {
    pub spans: Vec<SegmentSpan>,
}

impl SegmentBuffer {
    pub fn new(spans: Vec<SegmentSpan>) -> Self {
        Self { spans }
    }

    pub fn push(&mut self, span: SegmentSpan) {
        self.spans.push(span);
    }

    /// Returns the segment span immediately preceding the current insertion point (`spans[current - 1]`).
    pub fn previous(&self) -> Option<&SegmentSpan> {
        self.spans.last()
    }

    /// Explicitly returns `spans[self.len() - 1]` when non-empty, codifying `[current - 1]` relational lookup.
    pub fn current_minus_one(&self) -> Option<&SegmentSpan> {
        let current = self.spans.len();
        if current > 0 {
            self.spans.get(current - 1)
        } else {
            None
        }
    }
}

/// Helper function to format text with optional foreground colour and bold tags for `tmux`.
pub fn format_text(name: &str, text_col: Option<&str>, bold: bool) -> String {
    let fg_part = match text_col {
        Some(col) if !col.is_empty() && !col.eq_ignore_ascii_case("match_icon") => {
            format!("#[fg={}]", col)
        }
        _ => String::new(),
    };
    if bold {
        format!("{}#[bold]{}#[nobold]", fg_part, name)
    } else {
        format!("{}{}", fg_part, name)
    }
}

/// Formats a sequence of strings joined by a styled divider symbol (`#[fg=colour]{symbol}`).
pub fn format_pipeline(sections: &[String], symbol: &str, colour: &str, subtext_colour: Option<&str>) -> String {
    if sections.is_empty() {
        return String::new();
    }
    let separator = match subtext_colour {
        Some(sub) if !sub.is_empty() => {
            format!(" #[fg={colour}]{symbol} #[fg={sub}]", colour = colour, symbol = symbol, sub = sub)
        }
        _ => format!(" #[fg={colour}]{symbol} ", colour = colour, symbol = symbol),
    };
    sections.join(&separator)
}
