pub mod cpu;
pub mod memory;

use crate::bottombar::extension::system::cpu::CpuExtension;
use crate::bottombar::extension::system::memory::MemoryExtension;
use crate::bottombar::extension::{Extension, ExtensionContext, Group, GroupOutput};

/// Group containing system diagnostic extensions (`CpuExtension`, `MemoryExtension`).
pub struct SystemGroup {
    extensions: Vec<Box<dyn Extension>>,
}

impl SystemGroup {
    pub fn new() -> Self {
        Self {
            extensions: vec![
                Box::new(CpuExtension),
                Box::new(MemoryExtension),
            ],
        }
    }
}

impl Default for SystemGroup {
    fn default() -> Self {
        Self::new()
    }
}

impl Group for SystemGroup {
    fn name(&self) -> &'static str {
        "system"
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
    fn test_system_group_computes_outputs() {
        let _guard = crate::bottombar::cache::ENV_TEST_MUTEX
            .lock()
            .unwrap_or_else(|e| e.into_inner());
        let dir = std::env::temp_dir().join("autoname_sys_grp_test");
        let _ = std::fs::remove_dir_all(&dir);
        unsafe {
            std::env::set_var("AUTONAME_CACHE_DIR", &dir);
        }

        let cache = crate::bottombar::cache::GlobalCache::instance();
        cache.set("system_cpu_usage_pct", "14%");
        cache.set("system_overall_memory", "14.2G / 32G");

        let builder = TestContextBuilder::new();
        let ctx = builder.build();

        let grp = SystemGroup::new();
        let result = grp.compute(&ctx).expect("System group should trigger");
        assert_eq!(result.name, "system");
        assert_eq!(result.outputs.len(), 2);
        assert_eq!(result.outputs[0].text, "14%");
        assert_eq!(result.outputs[1].text, "14.2G / 32G");

        unsafe {
            std::env::remove_var("AUTONAME_CACHE_DIR");
        }
        let _ = std::fs::remove_dir_all(&dir);
    }
}
