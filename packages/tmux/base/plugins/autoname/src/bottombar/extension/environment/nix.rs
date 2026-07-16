use crate::bottombar::extension::{Extension, ExtensionContext, ExtensionOutput};
use crate::constants::colours;

/// Extension that detects active Nix shell environments (`IN_NIX_SHELL`) or Dev Containers (`DEVCONTAINER`).
pub struct NixExtension;

impl Extension for NixExtension {
    fn name(&self) -> &'static str {
        "nix"
    }

    fn compute(&self, ctx: &ExtensionContext) -> Option<ExtensionOutput> {
        if let Some(nix_shell) = ctx
            .env_vars
            .get("IN_NIX_SHELL")
            .or_else(|| ctx.env_vars.get("NIX_SHELL"))
            && !nix_shell.is_empty()
        {
            let text = if nix_shell == "pure" || nix_shell == "impure" {
                format!("nix-shell ({})", nix_shell)
            } else {
                "nix-shell".to_string()
            };
            return Some(ExtensionOutput {
                icon: "󱄅".to_string(),
                colour: colours::BLUE.to_string(),
                text,
            });
        }

        if let Some(dev_container) = ctx.env_vars.get("DEVCONTAINER")
            && (dev_container == "true" || dev_container == "1")
        {
            return Some(ExtensionOutput {
                icon: "".to_string(),
                colour: colours::MAUVE.to_string(),
                text: "devcontainer".to_string(),
            });
        }

        None
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::bottombar::extension::test_utils::TestContextBuilder;

    #[test]
    fn test_nix_shell_detection() {
        let builder = TestContextBuilder::new().env("IN_NIX_SHELL", "pure");
        let ctx = builder.build();

        let ext = NixExtension;
        let result = ext.compute(&ctx).expect("Should detect pure nix-shell");
        assert_eq!(result.icon, "󱄅");
        assert_eq!(result.text, "nix-shell (pure)");
    }

    #[test]
    fn test_devcontainer_detection() {
        let builder = TestContextBuilder::new().env("DEVCONTAINER", "true");
        let ctx = builder.build();

        let ext = NixExtension;
        let result = ext.compute(&ctx).expect("Should detect devcontainer");
        assert_eq!(result.icon, "");
        assert_eq!(result.text, "devcontainer");
    }

    #[test]
    fn test_nix_returns_none_if_absent() {
        let builder = TestContextBuilder::new();
        let ctx = builder.build();

        let ext = NixExtension;
        assert!(ext.compute(&ctx).is_none());
    }
}
