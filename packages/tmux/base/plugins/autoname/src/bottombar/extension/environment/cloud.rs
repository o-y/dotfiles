use crate::bottombar::extension::{Extension, ExtensionContext, ExtensionOutput};
use crate::constants::colours;

/// Extension that detects active GCP cloud projects (`GCP_PROJECT` / `CLOUDSDK_CORE_PROJECT`).
pub struct CloudExtension;

impl Extension for CloudExtension {
    fn name(&self) -> &'static str {
        "cloud"
    }

    fn compute(&self, ctx: &ExtensionContext) -> Option<ExtensionOutput> {
        if let Some(gcp_project) = ctx
            .env_vars
            .get("GCP_PROJECT")
            .or_else(|| ctx.env_vars.get("CLOUDSDK_CORE_PROJECT"))
            && !gcp_project.is_empty()
        {
            return Some(ExtensionOutput {
                icon: "".to_string(),
                colour: colours::BLUE.to_string(),
                text: format!("gcp: {}", gcp_project),
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
    fn test_cloud_gcp_project() {
        let builder = TestContextBuilder::new().env("GCP_PROJECT", "corp-analytics-prod");
        let ctx = builder.build();

        let ext = CloudExtension;
        let result = ext.compute(&ctx).expect("Should detect GCP project");
        assert_eq!(result.icon, "");
        assert_eq!(result.colour, colours::BLUE);
        assert_eq!(result.text, "gcp: corp-analytics-prod");
    }

    #[test]
    fn test_cloud_returns_none_if_absent() {
        let builder = TestContextBuilder::new();
        let ctx = builder.build();

        let ext = CloudExtension;
        assert!(ext.compute(&ctx).is_none());
    }
}
