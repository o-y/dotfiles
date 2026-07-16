use crate::bottombar::cache::GlobalCache;
use crate::bottombar::extension::{Extension, ExtensionContext, ExtensionOutput};
use crate::constants::colours;
use std::process::Command;
use std::time::Duration;

/// Extension that inspects active running Docker containers, globally cached using `GlobalCache`.
pub struct DockerExtension;

impl Extension for DockerExtension {
    fn name(&self) -> &'static str {
        "docker"
    }

    fn compute(&self, _ctx: &ExtensionContext) -> Option<ExtensionOutput> {
        let cache = GlobalCache::instance();
        let count_str = cache.get_or_compute(
            "docker_running_containers",
            Duration::from_secs(5),
            || {
                let output = Command::new("docker")
                    .args(["ps", "-q"])
                    .output()
                    .ok()?;
                if !output.status.success() {
                    return None;
                }
                let count = std::str::from_utf8(&output.stdout)
                    .ok()?
                    .lines()
                    .filter(|l| !l.trim().is_empty())
                    .count();
                Some(count.to_string())
            },
        )?;

        let count: usize = count_str.parse().ok()?;
        if count > 0 {
            let text = if count == 1 {
                "1 container".to_string()
            } else {
                format!("{} containers", count)
            };
            Some(ExtensionOutput {
                icon: "".to_string(),
                colour: colours::BLUE.to_string(),
                text,
            })
        } else {
            None
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::bottombar::extension::test_utils::TestContextBuilder;

    #[test]
    fn test_docker_extension_from_cached_count() {
        let _guard = crate::bottombar::cache::ENV_TEST_MUTEX
            .lock()
            .unwrap_or_else(|e| e.into_inner());
        let dir = std::env::temp_dir().join("autoname_docker_test_cache_1");
        let _ = std::fs::remove_dir_all(&dir);
        unsafe {
            std::env::set_var("AUTONAME_CACHE_DIR", &dir);
        }

        let cache = GlobalCache::instance();
        cache.set("docker_running_containers", "3");

        let builder = TestContextBuilder::new();
        let ctx = builder.build();

        let ext = DockerExtension;
        let result = ext.compute(&ctx).expect("Should format cached containers");
        assert_eq!(result.icon, "");
        assert_eq!(result.colour, colours::BLUE);
        assert_eq!(result.text, "3 containers");

        cache.set("docker_running_containers", "1");
        let result_single = ext.compute(&ctx).expect("Should format single container");
        assert_eq!(result_single.text, "1 container");

        unsafe {
            std::env::remove_var("AUTONAME_CACHE_DIR");
        }
        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn test_docker_extension_returns_none_when_zero() {
        let _guard = crate::bottombar::cache::ENV_TEST_MUTEX
            .lock()
            .unwrap_or_else(|e| e.into_inner());
        let dir = std::env::temp_dir().join("autoname_docker_test_cache_2");
        let _ = std::fs::remove_dir_all(&dir);
        unsafe {
            std::env::set_var("AUTONAME_CACHE_DIR", &dir);
        }

        let cache = GlobalCache::instance();
        cache.set("docker_running_containers", "0");

        let builder = TestContextBuilder::new();
        let ctx = builder.build();

        let ext = DockerExtension;
        assert!(ext.compute(&ctx).is_none());

        unsafe {
            std::env::remove_var("AUTONAME_CACHE_DIR");
        }
        let _ = std::fs::remove_dir_all(&dir);
    }
}
