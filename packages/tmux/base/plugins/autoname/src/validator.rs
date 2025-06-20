use crate::Args;

pub fn validate_args(args: &Args) -> Result<(), String> {
    validate_retrieve_value(&args.retrieve)
        .and(validate_panes_count(args.pane_count))
}

fn validate_retrieve_value(value: &str) -> Result<(), String> {
    const VALID_VALUES: &[&str] = &["tab_colour", "tab_name", "tab_icon", "tab_name_expanded"];
    if VALID_VALUES.contains(&&value.to_lowercase().as_str()) {
        Ok(())
    } else {
        Err(format!(
            "Invalid value for --retrieve: '{}'. Valid values are: {}.",
            value,
            VALID_VALUES.join(", ")
        ))
    }
}

fn validate_panes_count(value: u8) -> Result<(), String> {
    if value > 0 {
        Ok(())
    } else {
        Err(format!("Invalid value for --panes-count: '{}'. Must be greater than 0.", value))
    }
}