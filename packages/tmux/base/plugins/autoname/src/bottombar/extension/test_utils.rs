use crate::bottombar::extension::ExtensionContext;
use std::collections::HashMap;
use std::path::PathBuf;

/// Fluent builder for constructing `ExtensionContext` in unit tests consistently with minimal boilerplate.
pub struct TestContextBuilder {
    working_dir: PathBuf,
    process_name: String,
    pane_pid: Option<u32>,
    env_vars: HashMap<String, String>,
}

impl Default for TestContextBuilder {
    fn default() -> Self {
        Self::new()
    }
}

impl TestContextBuilder {
    /// Creates a fresh test context builder with sensible defaults (`/home/runner`, `zsh`, `1234`).
    pub fn new() -> Self {
        Self {
            working_dir: PathBuf::from("/home/runner"),
            process_name: "zsh".to_string(),
            pane_pid: Some(1234),
            env_vars: HashMap::new(),
        }
    }

    /// Sets the working directory of the mock pane.
    pub fn working_dir(mut self, path: impl Into<PathBuf>) -> Self {
        self.working_dir = path.into();
        self
    }

    /// Sets the active process name of the mock pane (`zsh`, `python`, `docker`).
    pub fn process_name(mut self, name: &str) -> Self {
        self.process_name = name.to_string();
        self
    }

    /// Sets the pane process ID (`#{pane_pid}`).
    pub fn pane_pid(mut self, pid: Option<u32>) -> Self {
        self.pane_pid = pid;
        self
    }

    /// Inserts a single environment variable (`KEY=VALUE`) into the mock process environment.
    pub fn env(mut self, key: &str, value: &str) -> Self {
        self.env_vars.insert(key.to_string(), value.to_string());
        self
    }

    /// Inserts multiple environment variables into the mock process environment.
    pub fn envs(mut self, vars: &[(&str, &str)]) -> Self {
        for (k, v) in vars {
            self.env_vars.insert(k.to_string(), v.to_string());
        }
        self
    }

    /// Builds and returns the borrowed `ExtensionContext` referencing this builder's data.
    pub fn build(&self) -> ExtensionContext<'_> {
        ExtensionContext {
            working_dir: &self.working_dir,
            process_name: &self.process_name,
            pane_pid: self.pane_pid,
            env_vars: &self.env_vars,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::path::Path;

    #[test]
    fn test_test_context_builder_defaults() {
        let builder = TestContextBuilder::new();
        let ctx = builder.build();
        assert_eq!(ctx.working_dir, Path::new("/home/runner"));
        assert_eq!(ctx.process_name, "zsh");
        assert_eq!(ctx.pane_pid, Some(1234));
        assert!(ctx.env_vars.is_empty());
    }

    #[test]
    fn test_test_context_builder_custom() {
        let builder = TestContextBuilder::new()
            .working_dir("/root/project")
            .process_name("cargo")
            .pane_pid(Some(9999))
            .env("MY_KEY", "my_val");
        let ctx = builder.build();
        assert_eq!(ctx.working_dir, Path::new("/root/project"));
        assert_eq!(ctx.process_name, "cargo");
        assert_eq!(ctx.pane_pid, Some(9999));
        assert_eq!(ctx.env_vars.get("MY_KEY"), Some(&"my_val".to_string()));
    }
}
