pub mod jobs;

use crate::bottombar::extension::background::jobs::JobsExtension;
use crate::bottombar::extension::{Extension, ExtensionContext, Group, GroupOutput};

/// Group containing background / stopped process awareness (`jobs`).
pub struct BackgroundGroup {
    extensions: Vec<Box<dyn Extension>>,
}

impl BackgroundGroup {
    pub fn new() -> Self {
        Self {
            extensions: vec![Box::new(JobsExtension)],
        }
    }
}

impl Default for BackgroundGroup {
    fn default() -> Self {
        Self::new()
    }
}

impl Group for BackgroundGroup {
    fn name(&self) -> &'static str {
        "background"
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
    fn test_background_group_computes_none_when_empty() {
        let builder = TestContextBuilder::new();
        let ctx = builder.build();
        let grp = BackgroundGroup::new();
        assert!(grp.compute(&ctx).is_none());
    }
}
