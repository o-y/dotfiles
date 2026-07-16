pub mod cloud;
pub mod nix;
pub mod virtualenv;

use crate::bottombar::extension::environment::cloud::CloudExtension;
use crate::bottombar::extension::environment::nix::NixExtension;
use crate::bottombar::extension::environment::virtualenv::VirtualenvExtension;
use crate::bottombar::extension::{Extension, ExtensionContext, Group, GroupOutput};

/// Group containing virtual environment and cloud context extensions (`VirtualenvExtension`, `CloudExtension`, `NixExtension`).
pub struct EnvironmentGroup {
    extensions: Vec<Box<dyn Extension>>,
}

impl EnvironmentGroup {
    pub fn new() -> Self {
        Self {
            extensions: vec![
                Box::new(VirtualenvExtension),
                Box::new(CloudExtension),
                Box::new(NixExtension),
            ],
        }
    }
}

impl Default for EnvironmentGroup {
    fn default() -> Self {
        Self::new()
    }
}

impl Group for EnvironmentGroup {
    fn name(&self) -> &'static str {
        "environment"
    }

    fn extensions(&self) -> &[Box<dyn Extension>] {
        &self.extensions
    }

    fn compute(&self, ctx: &ExtensionContext) -> Option<GroupOutput> {
        let mut outputs = Vec::new();
        for ext in &self.extensions {
            if let Some(out) = ext.compute(ctx) {
                outputs.push(out);
            }
        }
        if outputs.is_empty() {
            None
        } else {
            Some(GroupOutput {
                name: self.name(),
                outputs,
            })
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::bottombar::extension::test_utils::TestContextBuilder;

    #[test]
    fn test_environment_group_computes_outputs() {
        let builder = TestContextBuilder::new()
            .env("PIXI_PROJECT_NAME", "my-app")
            .env("PIXI_ENVIRONMENT_NAME", "dev")
            .env("GCP_PROJECT", "corp-prod");
        let ctx = builder.build();

        let grp = EnvironmentGroup::new();
        let result = grp.compute(&ctx).expect("Environment group should trigger");
        assert_eq!(result.name, "environment");
        assert_eq!(result.outputs.len(), 2);
        assert_eq!(result.outputs[0].text, "my-app:dev");
        assert_eq!(result.outputs[1].text, "gcp: corp-prod");
    }
}
