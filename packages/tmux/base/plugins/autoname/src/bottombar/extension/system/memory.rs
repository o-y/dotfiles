use crate::bottombar::cache::GlobalCache;
use crate::bottombar::extension::{Extension, ExtensionContext, ExtensionOutput};
use crate::constants::colours;
use std::time::Duration;
use sysinfo::System;

/// Extension that inspects overall system physical RAM usage (`14.2G / 32G`), globally cached.
pub struct MemoryExtension;

impl Extension for MemoryExtension {
    fn name(&self) -> &'static str {
        "memory"
    }

    fn compute(&self, _ctx: &ExtensionContext) -> Option<ExtensionOutput> {
        let cache = GlobalCache::instance();
        let text = cache.get_or_compute("system_overall_memory", Duration::from_secs(2), || {
            let mut sys = System::new();
            sys.refresh_memory();
            let total = sys.total_memory();
            if total == 0 {
                return None;
            }
            let used = sys.used_memory();
            Some(format!("{} / {}", format_memory(used), format_memory(total)))
        })?;

        Some(ExtensionOutput {
            icon: "󰍛".to_string(),
            colour: colours::MAUVE.to_string(),
            text,
        })
    }
}

/// Formats raw memory bytes into a concise string, dropping `.0` for exact gigabyte figures (`32G`, `14.2G`).
pub fn format_memory(bytes: u64) -> String {
    const KB: u64 = 1024;
    const MB: u64 = KB * 1024;
    const GB: u64 = MB * 1024;

    if bytes >= GB {
        let val = bytes as f64 / GB as f64;
        if val.fract().abs() < 0.05 {
            format!("{:.0}G", val)
        } else {
            format!("{:.1}G", val)
        }
    } else if bytes >= MB {
        format!("{}M", bytes / MB)
    } else if bytes >= KB {
        format!("{}K", bytes / KB)
    } else {
        format!("{}B", bytes)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::bottombar::extension::test_utils::TestContextBuilder;

    #[test]
    fn test_format_memory_units() {
        assert_eq!(format_memory(512), "512B");
        assert_eq!(format_memory(1024 * 45), "45K");
        assert_eq!(format_memory(1024 * 1024 * 420), "420M");
        assert_eq!(format_memory(1024 * 1024 * 1024 * 32), "32G");
        assert_eq!(format_memory(1024 * 1024 * 1024 * 14 + 1024 * 1024 * 200), "14.2G");
    }

    #[test]
    fn test_memory_extension_uses_cached_overall_ram() {
        let _guard = crate::bottombar::cache::ENV_TEST_MUTEX
            .lock()
            .unwrap_or_else(|e| e.into_inner());
        let dir = std::env::temp_dir().join("autoname_mem_test_cache_1");
        let _ = std::fs::remove_dir_all(&dir);
        unsafe {
            std::env::set_var("AUTONAME_CACHE_DIR", &dir);
        }

        let cache = GlobalCache::instance();
        cache.set("system_overall_memory", "14.2G / 32G");

        let builder = TestContextBuilder::new();
        let ctx = builder.build();

        let ext = MemoryExtension;
        let result = ext.compute(&ctx).expect("Should return cached overall RAM");
        assert_eq!(result.icon, "󰍛");
        assert_eq!(result.colour, colours::MAUVE);
        assert_eq!(result.text, "14.2G / 32G");

        unsafe {
            std::env::remove_var("AUTONAME_CACHE_DIR");
        }
        let _ = std::fs::remove_dir_all(&dir);
    }
}
