use regex::{Captures, Regex};
use std::path::Path;
use std::sync::OnceLock;

#[derive(Debug, Clone)]
pub struct TemplateContext<'a> {
    pub working_dir: &'a Path,
    pub process_name: &'a str,
    pub pane_title: &'a str,
}

impl<'a> TemplateContext<'a> {
    pub fn new(working_dir: &'a Path, process_name: &'a str, pane_title: &'a str) -> Self {
        Self {
            working_dir,
            process_name,
            pane_title,
        }
    }
}

/// A trait for pluggable variable resolvers evaluated inside templates (`{{var}}`).
pub trait VariableResolver {
    fn resolve(&self, var_name: &str, ctx: &TemplateContext) -> Option<String>;
}

pub struct PathResolver;
pub struct ProcessResolver;
pub struct VcsResolver;

impl VariableResolver for PathResolver {
    fn resolve(&self, var_name: &str, ctx: &TemplateContext) -> Option<String> {
        match var_name {
            "pwd" | "dir" | "cwd" => Some(crate::tabs::retriever::format_directory_path(ctx.working_dir)),
            "pwd_expanded" | "dir_expanded" => {
                Some(crate::tabs::retriever::format_expanded_directory_path(ctx.working_dir))
            }
            _ => None,
        }
    }
}

impl VariableResolver for ProcessResolver {
    fn resolve(&self, var_name: &str, ctx: &TemplateContext) -> Option<String> {
        match var_name {
            "proc" | "process" => Some(ctx.process_name.to_string()),
            "pane_title" | "title" => Some(ctx.pane_title.to_string()),
            _ => None,
        }
    }
}

impl VariableResolver for VcsResolver {
    fn resolve(&self, var_name: &str, ctx: &TemplateContext) -> Option<String> {
        match var_name {
            "vcs_branch" => Some(
                crate::vcs::VcsAppearance::compute(ctx.working_dir)
                    .map(|v| v.branch)
                    .unwrap_or_default(),
            ),
            _ => None,
        }
    }
}

/// Resolves a single variable name within a given `TemplateContext` by querying registered `VariableResolver` instances.
pub fn resolve_variable(var_name: &str, ctx: &TemplateContext) -> String {
    let resolvers: &[&dyn VariableResolver] = &[&PathResolver, &ProcessResolver, &VcsResolver];
    for resolver in resolvers {
        if let Some(val) = resolver.resolve(var_name, ctx) {
            return val;
        }
    }
    format!("{{{{{var_name}}}}}")
}

/// Resolves live variable placeholders (`{{var}}`) within a template string using a single-pass regex scanner.
pub fn resolve_template(template: &str, ctx: &TemplateContext) -> String {
    static TEMPLATE_RE: OnceLock<Regex> = OnceLock::new();
    let re = TEMPLATE_RE.get_or_init(|| Regex::new(r"\{\{([^{}]+)\}\}").expect("Valid template regex"));

    re.replace_all(template, |caps: &Captures| {
        let var_name = caps.get(1).map_or("", |m| m.as_str()).trim();
        resolve_variable(var_name, ctx)
    })
    .into_owned()
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::path::PathBuf;

    #[test]
    fn test_resolve_pwd_and_proc_variables() {
        let path = PathBuf::from("/mnt/storage/work/odyssey");
        let ctx = TemplateContext::new(&path, "zsh", "zsh - storage");
        assert_eq!(resolve_template("{{pwd}}", &ctx), "odyssey");
        assert_eq!(resolve_template("{{dir}}", &ctx), "odyssey");
        assert_eq!(resolve_template("{{cwd}}", &ctx), "odyssey");
        assert_eq!(resolve_template("{{proc}}", &ctx), "zsh");
        assert_eq!(resolve_template("{{pwd}} · {{proc}}", &ctx), "odyssey · zsh");
    }

    #[test]
    fn test_resolve_pane_title_variable() {
        let path = PathBuf::from("/mnt/storage/work/odyssey");
        let ctx = TemplateContext::new(&path, "ssh", "ssh user@dev-server-01");
        assert_eq!(
            resolve_template("Connected to {{pane_title}}", &ctx),
            "Connected to ssh user@dev-server-01"
        );
        assert_eq!(resolve_template("{{title}}", &ctx), "ssh user@dev-server-01");
    }

    #[test]
    fn test_resolve_whitespace_resilience_and_unknown_variables() {
        let path = PathBuf::from("/mnt/storage/work/odyssey");
        let ctx = TemplateContext::new(&path, "nvim", "nvim - odyssey");
        assert_eq!(resolve_template("{{ pwd }}", &ctx), "odyssey");
        assert_eq!(resolve_template("{{   proc   }} [{{unknown_var}}]", &ctx), "nvim [{{unknown_var}}]");
    }
}
