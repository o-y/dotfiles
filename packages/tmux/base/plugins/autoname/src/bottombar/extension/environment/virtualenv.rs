use crate::bottombar::extension::{Extension, ExtensionContext, ExtensionOutput};
use crate::constants::colours;

/// Extension that detects active Python / Pixi / Conda virtual environments directly from environment variables.
pub struct VirtualenvExtension;

impl Extension for VirtualenvExtension {
    fn name(&self) -> &'static str {
        "virtualenv"
    }

    fn compute(&self, ctx: &ExtensionContext) -> Option<ExtensionOutput> {
        let text = Self::detect_name(ctx)?;
        Some(ExtensionOutput {
            icon: "󰌠".to_string(),
            colour: colours::YELLOW.to_string(),
            text,
        })
    }
}

impl VirtualenvExtension {
    fn detect_name(ctx: &ExtensionContext) -> Option<String> {
        if let Some(proj) = ctx.env_vars.get("PIXI_PROJECT_NAME").filter(|s| !s.is_empty()) {
            let env = ctx
                .env_vars
                .get("PIXI_ENVIRONMENT_NAME")
                .map(String::as_str)
                .unwrap_or("default");
            return Some(if env == "default" {
                proj.clone()
            } else {
                format!("{proj}:{env}")
            });
        }

        if let Some(prompt) = ctx.env_vars.get("PIXI_PROMPT").filter(|s| !s.is_empty()) {
            let clean = prompt.trim_matches(|c| c == '(' || c == ')').trim();
            if !clean.is_empty() {
                return Some(clean.to_string());
            }
        }

        if let Some(venv) = ctx.env_vars.get("VIRTUAL_ENV").filter(|s| !s.is_empty()) {
            let parts: Vec<&str> = venv.split('/').filter(|s| !s.is_empty()).collect();
            if let Some(&last) = parts.last() {
                let name = if matches!(
                    last,
                    ".venv" | "venv" | ".virtualenv" | "virtualenv" | "env" | ".env"
                ) && parts.len() > 1
                {
                    parts[parts.len() - 2]
                } else {
                    last
                };
                if !name.is_empty() {
                    return Some(name.to_string());
                }
            }
        }

        ctx.env_vars
            .get("CONDA_DEFAULT_ENV")
            .filter(|&e| !e.is_empty() && e != "base")
            .cloned()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::bottombar::extension::test_utils::TestContextBuilder;

    #[test]
    fn test_virtualenv_from_pixi_project_and_env() {
        let builder = TestContextBuilder::new()
            .env("PIXI_PROJECT_NAME", "my-pixi-app")
            .env("PIXI_ENVIRONMENT_NAME", "dev");
        let ctx = builder.build();

        let ext = VirtualenvExtension;
        let result = ext.compute(&ctx).expect("Should detect pixi environment");
        assert_eq!(result.icon, "󰌠");
        assert_eq!(result.colour, colours::YELLOW);
        assert_eq!(result.text, "my-pixi-app:dev");

        let builder_default = TestContextBuilder::new()
            .env("PIXI_PROJECT_NAME", "my-pixi-app")
            .env("PIXI_ENVIRONMENT_NAME", "default");
        let ctx_default = builder_default.build();
        let result_default = ext
            .compute(&ctx_default)
            .expect("Should detect default pixi environment");
        assert_eq!(result_default.text, "my-pixi-app");
    }

    #[test]
    fn test_virtualenv_from_pixi_prompt() {
        let builder = TestContextBuilder::new().env("PIXI_PROMPT", "(data-pipeline)");
        let ctx = builder.build();

        let ext = VirtualenvExtension;
        let result = ext.compute(&ctx).expect("Should detect pixi prompt");
        assert_eq!(result.text, "data-pipeline");
    }

    #[test]
    fn test_virtualenv_from_virtual_env_variable() {
        let builder = TestContextBuilder::new()
            .working_dir("/home/runner/projects/mytool")
            .env("VIRTUAL_ENV", "/home/runner/projects/mytool/.venv");
        let ctx = builder.build();

        let ext = VirtualenvExtension;
        let result = ext.compute(&ctx).expect("Should detect virtualenv");
        assert_eq!(result.icon, "󰌠");
        assert_eq!(result.colour, colours::YELLOW);
        assert_eq!(result.text, "mytool");
    }

    #[test]
    fn test_virtualenv_from_conda_variable_ignoring_base() {
        let builder = TestContextBuilder::new().env("CONDA_DEFAULT_ENV", "base");
        let ctx = builder.build();

        let ext = VirtualenvExtension;
        assert!(ext.compute(&ctx).is_none());

        let builder2 = TestContextBuilder::new().env("CONDA_DEFAULT_ENV", "py-analytics");
        let ctx2 = builder2.build();
        let result = ext.compute(&ctx2).expect("Should detect conda env");
        assert_eq!(result.text, "py-analytics");
    }

    #[test]
    fn test_virtualenv_returns_none_when_no_env_present() {
        let builder = TestContextBuilder::new();
        let ctx = builder.build();

        let ext = VirtualenvExtension;
        assert!(ext.compute(&ctx).is_none());
    }
}
