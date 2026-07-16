use crate::constants::{colours, icons, processes, symbols};
use crate::tabs::template::{resolve_template, TemplateContext};
use regex::Regex;
use std::borrow::Cow;
use std::collections::HashMap;
use std::path::{Path, PathBuf};

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct FontStyle {
    pub bold: bool,
    pub text_colour: String,
}

impl Default for FontStyle {
    fn default() -> Self {
        Self {
            bold: true,
            text_colour: "match_icon".to_string(),
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct DividerStyle {
    pub symbol: String,
    pub colour: String,
}

impl Default for DividerStyle {
    fn default() -> Self {
        Self {
            symbol: symbols::CHEVRON_RIGHT.to_string(),
            colour: colours::DIVIDER_GREY.to_string(),
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct StyleConfig {
    pub font: FontStyle,
    pub process_divider: DividerStyle,
    pub badge_divider: DividerStyle,
}

impl Default for StyleConfig {
    fn default() -> Self {
        Self {
            font: FontStyle::default(),
            process_divider: DividerStyle {
                symbol: symbols::CHEVRON_RIGHT.to_string(),
                colour: colours::DIVIDER_GREY.to_string(),
            },
            badge_divider: DividerStyle {
                symbol: symbols::VERTICAL_PIPE.to_string(),
                colour: colours::DIVIDER_GREY.to_string(),
            },
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PanesConfig {
    pub enabled: bool,
    pub icon: String,
    pub colour: String,
}

impl Default for PanesConfig {
    fn default() -> Self {
        Self {
            enabled: true,
            icon: icons::MULTI_PANE.to_string(),
            colour: colours::MAUVE.to_string(),
        }
    }
}

impl PanesConfig {
    pub fn resolve_colour<'a>(&'a self, left_colour: Option<&'a str>) -> &'a str {
        if self.inherits_left() {
            left_colour.unwrap_or(&self.colour)
        } else {
            &self.colour
        }
    }

    pub fn inherits_left(&self) -> bool {
        self.colour.eq_ignore_ascii_case("match_left")
            || self.colour.eq_ignore_ascii_case("inherit_left")
            || self.colour.eq_ignore_ascii_case("match_previous")
            || self.colour.eq_ignore_ascii_case("inherit")
    }
}

#[derive(Debug, Clone)]
pub enum TabNamingRule {
    Static(String),
    Pattern(Regex),
    Template(String),
    Default,
}

impl PartialEq for TabNamingRule {
    fn eq(&self, other: &Self) -> bool {
        match (self, other) {
            (Self::Static(a), Self::Static(b)) => a == b,
            (Self::Pattern(a), Self::Pattern(b)) => a.as_str() == b.as_str(),
            (Self::Template(a), Self::Template(b)) => a == b,
            (Self::Default, Self::Default) => true,
            _ => false,
        }
    }
}

impl Eq for TabNamingRule {}

impl TabNamingRule {
    pub fn from_options(
        pattern: Option<&String>,
        static_name: Option<&String>,
        live_template: Option<&String>,
    ) -> Self {
        if let Some(re_str) = pattern {
            Regex::new(re_str).map(Self::Pattern).unwrap_or(Self::Default)
        } else if let Some(template) = live_template {
            Self::Template(template.clone())
        } else if let Some(name) = static_name {
            Self::Static(name.clone())
        } else {
            Self::Default
        }
    }

    pub fn resolve<'a>(&'a self, target_str: &'a str, fallback: &'a str, ctx: &TemplateContext) -> Cow<'a, str> {
        match self {
            Self::Static(name) => Cow::Borrowed(name.as_str()),
            Self::Pattern(re) => re
                .captures(target_str)
                .and_then(|caps| caps.get(1).or(caps.get(0)))
                .map(|m| Cow::Borrowed(m.as_str()))
                .unwrap_or(Cow::Borrowed(fallback)),
            Self::Template(template) => Cow::Owned(resolve_template(template, ctx)),
            Self::Default => Cow::Borrowed(fallback),
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct AppearanceRule {
    pub icon: String,
    pub colour: String,
    pub naming_rule: TabNamingRule,
    pub bold: Option<bool>,
}

impl AppearanceRule {
    pub fn bold(&self, style: &StyleConfig) -> bool {
        self.bold.unwrap_or(style.font.bold)
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ProcessInfo {
    pub appearance: AppearanceRule,
    pub ignored: bool,
}

impl ProcessInfo {
    pub fn icon(&self) -> &str {
        &self.appearance.icon
    }

    pub fn colour(&self) -> &str {
        &self.appearance.colour
    }

    pub fn bold(&self, style: &StyleConfig) -> bool {
        self.appearance.bold(style)
    }

    pub fn resolve_tab_name(&self, process_name: &str, pane_title: &str, ctx: &TemplateContext) -> String {
        self.appearance.naming_rule.resolve(pane_title, process_name, ctx).into_owned()
    }

    pub fn is_ignored(&self) -> bool {
        self.ignored
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct DirectoryInfo {
    pub path: PathBuf,
    pub exact: bool,
    pub appearance: AppearanceRule,
    pub process_context: bool,
}

impl DirectoryInfo {
    pub fn icon(&self) -> &str {
        &self.appearance.icon
    }

    pub fn colour(&self) -> &str {
        &self.appearance.colour
    }

    pub fn bold(&self, style: &StyleConfig) -> bool {
        self.appearance.bold(style)
    }

    pub fn matches(&self, working_dir: &Path) -> bool {
        if self.exact {
            working_dir == self.path
        } else {
            working_dir.starts_with(&self.path)
        }
    }

    pub fn resolve_tab_name(&self, working_dir: &Path, ctx: &TemplateContext) -> String {
        let default_fallback = crate::tabs::retriever::format_directory_path(working_dir);
        self.appearance
            .naming_rule
            .resolve(working_dir.to_str().unwrap_or(""), &default_fallback, ctx)
            .into_owned()
    }

    pub fn format_process_tab(&self, dir_name: &str, proc_name: &str, style: &StyleConfig) -> String {
        format!("{} {} {}", dir_name, style.process_divider.symbol, proc_name)
    }

    pub fn should_show_process_context(&self) -> bool {
        self.process_context
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ProcessDefault {
    pub icon: String,
    pub colour: String,
}

impl Default for ProcessDefault {
    fn default() -> Self {
        Self {
            icon: icons::TERMINAL.to_string(),
            colour: colours::BLUE.to_string(),
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct ProcessesConfig {
    pub default: ProcessDefault,
    pub rules: HashMap<String, ProcessInfo>,
}

#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct DirectoriesConfig {
    pub rules: Vec<DirectoryInfo>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct AppConfig {
    pub process: ProcessesConfig,
    pub directory: DirectoriesConfig,
    pub style: StyleConfig,
    pub panes: PanesConfig,
}

impl Default for AppConfig {
    fn default() -> Self {
        let mut process_rules = HashMap::new();
        for name in processes::BUILTIN_SHELLS {
            process_rules.insert(
                name.to_string(),
                ProcessInfo {
                    appearance: AppearanceRule {
                        icon: icons::TERMINAL.to_string(),
                        colour: colours::BLUE.to_string(),
                        naming_rule: TabNamingRule::Default,
                        bold: None,
                    },
                    ignored: true,
                },
            );
        }

        let root_dir = DirectoryInfo {
            path: PathBuf::from("/"),
            exact: false,
            appearance: AppearanceRule {
                icon: "".to_string(),
                colour: colours::YELLOW.to_string(),
                naming_rule: TabNamingRule::Default,
                bold: None,
            },
            process_context: false,
        };

        Self {
            process: ProcessesConfig {
                default: ProcessDefault::default(),
                rules: process_rules,
            },
            directory: DirectoriesConfig {
                rules: vec![root_dir],
            },
            style: StyleConfig::default(),
            panes: PanesConfig::default(),
        }
    }
}

impl AppConfig {
    pub fn find_directory(&self, working_dir: &Path) -> Option<&DirectoryInfo> {
        self.directory
            .rules
            .iter()
            .filter(|dir| dir.matches(working_dir))
            .max_by_key(|dir| dir.path.as_os_str().len())
    }

    pub fn find_process(&self, process_name: &str) -> Option<&ProcessInfo> {
        self.process.rules.get(process_name)
    }
}
