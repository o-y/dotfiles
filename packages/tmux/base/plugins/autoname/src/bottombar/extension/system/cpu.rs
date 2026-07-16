use crate::bottombar::cache::GlobalCache;
use crate::bottombar::extension::{Extension, ExtensionContext, ExtensionOutput};
use crate::constants::{colours, icons};
use std::time::Duration;
use sysinfo::System;

/// Extension that inspects overall host CPU utilization percentage (` 14%`), globally cached across panes.
pub struct CpuExtension;

impl Extension for CpuExtension {
    fn name(&self) -> &'static str {
        "cpu"
    }

    fn compute(&self, _ctx: &ExtensionContext) -> Option<ExtensionOutput> {
        let cache = GlobalCache::instance();
        let text = cache.get_or_compute("system_cpu_usage_pct", Duration::from_secs(2), || {
            let mut sys = System::new();
            sys.refresh_cpu_usage();
            std::thread::sleep(Duration::from_millis(60));
            sys.refresh_cpu_usage();
            let usage = sys.global_cpu_usage();
            Some(format!("{:.0}%", usage))
        })?;

        Some(ExtensionOutput {
            icon: icons::CPU.to_string(),
            colour: colours::PEACH.to_string(),
            text,
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::bottombar::extension::test_utils::TestContextBuilder;

    #[test]
    fn test_cpu_extension_uses_cached_value() {
        let _guard = crate::bottombar::cache::ENV_TEST_MUTEX
            .lock()
            .unwrap_or_else(|e| e.into_inner());
        let dir = std::env::temp_dir().join("autoname_cpu_test_cache_1");
        let _ = std::fs::remove_dir_all(&dir);
        unsafe {
            std::env::set_var("AUTONAME_CACHE_DIR", &dir);
        }

        let cache = GlobalCache::instance();
        cache.set("system_cpu_usage_pct", "18%");

        let builder = TestContextBuilder::new();
        let ctx = builder.build();

        let ext = CpuExtension;
        let result = ext.compute(&ctx).expect("Should return cached CPU usage");
        assert_eq!(result.icon, icons::CPU);
        assert_eq!(result.colour, colours::PEACH);
        assert_eq!(result.text, "18%");

        unsafe {
            std::env::remove_var("AUTONAME_CACHE_DIR");
        }
        let _ = std::fs::remove_dir_all(&dir);
    }
}
