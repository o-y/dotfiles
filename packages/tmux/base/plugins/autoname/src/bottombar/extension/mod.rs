pub mod background;
pub mod builds;
pub mod environment;
pub mod servers;
pub mod system;
pub mod test_utils;

use crate::appearance::SegmentSpan;
use std::collections::HashMap;
use std::path::Path;

/// Context passed to each extension and group during concurrent evaluation of the bottom bar.
#[derive(Debug, Clone, Copy)]
pub struct ExtensionContext<'a> {
    /// The current working directory of the pane.
    pub working_dir: &'a Path,
    /// The name of the active process inside the pane (e.g. `zsh`, `python`, `cargo`).
    pub process_name: &'a str,
    /// The process ID (PID) of the active shell/command in the pane (`#{pane_pid}`).
    pub pane_pid: Option<u32>,
    /// Environment variables belonging to the target pane's process (`/proc/<pid>/environ`).
    pub env_vars: &'a HashMap<String, String>,
}

/// Output produced by a single extension when it successfully retrieves and formats metadata.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ExtensionOutput {
    /// The Nerd Font icon representing this extension (`󰌠`, ``, `󰖪`).
    pub icon: String,
    /// The primary hex colour representing this extension (`#hex`).
    pub colour: String,
    /// The concise value string retrieved by the extension (`jetski`, `14%`, `:8080`).
    pub text: String,
}

impl ExtensionOutput {
    pub fn as_span(&self) -> SegmentSpan {
        SegmentSpan::new(&self.text, &self.colour).with_icon(&self.icon)
    }
}

impl From<&ExtensionOutput> for SegmentSpan {
    fn from(out: &ExtensionOutput) -> Self {
        out.as_span()
    }
}

/// Output produced by a group of extensions (`SystemGroup`, `ServersGroup`, `EnvironmentGroup`).
/// Each group renders as a distinct oval pill (`...`) across the bottom border of the pane.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct GroupOutput {
    /// Unique single-word identifier of the group (`system`, `servers`, `environment`).
    pub name: &'static str,
    /// The list of outputs produced by all triggered extensions belonging to this group.
    pub outputs: Vec<ExtensionOutput>,
}

/// Trait implemented by all individual bottombar extensions.
pub trait Extension: Send + Sync {
    /// Unique single-word identifier of the extension (`cpu`, `ports`, `virtualenv`).
    fn name(&self) -> &'static str;

    /// Evaluates whether this extension should trigger in the current pane context.
    fn compute(&self, ctx: &ExtensionContext) -> Option<ExtensionOutput>;
}

/// Trait implemented by all bottombar groups (`SystemGroup`, `ServersGroup`, `EnvironmentGroup`).
/// Groups organize related `Extension` items into discrete oval pills on the bottom border.
pub trait Group: Send + Sync {
    /// Unique single-word identifier of the group (`system`, `servers`, `environment`).
    fn name(&self) -> &'static str;

    /// Returns all member extensions registered inside this group.
    fn extensions(&self) -> &[Box<dyn Extension>];

    /// Evaluates all member extensions concurrently or sequentially, returning `Some(GroupOutput)`
    /// when at least one extension triggers.
    fn compute(&self, ctx: &ExtensionContext) -> Option<GroupOutput>;
}

/// Returns all registered bottombar groups in rendering order from left to right on the border.
pub fn all_groups() -> Vec<Box<dyn Group>> {
    vec![
        Box::new(environment::EnvironmentGroup::new()),
        Box::new(builds::BuildsGroup::new()),
        Box::new(servers::ServersGroup::new()),
        Box::new(background::BackgroundGroup::new()),
        Box::new(system::SystemGroup::new()),
    ]
}

/// Returns all registered individual extensions across all groups.
pub fn all_extensions() -> Vec<Box<dyn Extension>> {
    vec![
        Box::new(environment::virtualenv::VirtualenvExtension),
        Box::new(servers::docker::DockerExtension),
        Box::new(environment::cloud::CloudExtension),
        Box::new(environment::nix::NixExtension),
        Box::new(servers::ports::PortsExtension),
        Box::new(system::cpu::CpuExtension),
        Box::new(system::memory::MemoryExtension),
        Box::new(background::jobs::JobsExtension),
        Box::new(builds::blaze::BlazeExtension),
    ]
}
