pub mod docker;
pub mod ports;

use crate::bottombar::extension::servers::docker::DockerExtension;
use crate::bottombar::extension::servers::ports::PortsExtension;
use crate::bottombar::extension::{Extension, ExtensionContext, Group, GroupOutput};

/// Group containing server, networking, and container extensions (`PortsExtension`, `DockerExtension`).
pub struct ServersGroup {
    extensions: Vec<Box<dyn Extension>>,
}

impl ServersGroup {
    pub fn new() -> Self {
        Self {
            extensions: vec![
                Box::new(PortsExtension),
                Box::new(DockerExtension),
            ],
        }
    }
}

impl Default for ServersGroup {
    fn default() -> Self {
        Self::new()
    }
}

impl Group for ServersGroup {
    fn name(&self) -> &'static str {
        "servers"
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
    fn test_servers_group_computes_outputs() {
        let _guard = crate::bottombar::cache::ENV_TEST_MUTEX
            .lock()
            .unwrap_or_else(|e| e.into_inner());
        let dir = std::env::temp_dir().join("autoname_srv_grp_test");
        let _ = std::fs::remove_dir_all(&dir);
        unsafe {
            std::env::set_var("AUTONAME_CACHE_DIR", &dir);
        }

        let cache = crate::bottombar::cache::GlobalCache::instance();
        cache.set("docker_running_containers", "2");

        let builder = TestContextBuilder::new().pane_pid(Some(1234));
        let ctx = builder.build();

        let grp = ServersGroup::new();
        let result = grp.compute(&ctx).expect("Servers group should trigger from docker");
        assert_eq!(result.name, "servers");
        assert!(result.outputs.iter().any(|o| o.text == "2 containers"));

        unsafe {
            std::env::remove_var("AUTONAME_CACHE_DIR");
        }
        let _ = std::fs::remove_dir_all(&dir);
    }
}
