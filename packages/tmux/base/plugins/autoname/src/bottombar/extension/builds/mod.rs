pub mod blaze;

use crate::bottombar::extension::builds::blaze::BlazeExtension;
use crate::bottombar::extension::{Extension, ExtensionContext, Group, GroupOutput};

/// Group containing build / test toolchain awareness (`blaze`).
pub struct BuildsGroup {
    extensions: Vec<Box<dyn Extension>>,
}

impl BuildsGroup {
    pub fn new() -> Self {
        Self {
            extensions: vec![Box::new(BlazeExtension)],
        }
    }
}

impl Default for BuildsGroup {
    fn default() -> Self {
        Self::new()
    }
}

impl Group for BuildsGroup {
    fn name(&self) -> &'static str {
        "builds"
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
    fn test_builds_group_computes_none_when_empty() {
        let builder = TestContextBuilder::new();
        let ctx = builder.build();
        let grp = BuildsGroup::new();
        assert!(grp.compute(&ctx).is_none());
    }
}
