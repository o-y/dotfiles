use std::fs::{self, File};
use std::io::Write;
use std::path::PathBuf;
use std::time::{Duration, SystemTime};

#[cfg(test)]
pub static ENV_TEST_MUTEX: std::sync::Mutex<()> = std::sync::Mutex::new(());

/// A file-backed global cache for sharing expensive or system-wide state
/// (e.g. running Docker containers, cloud status) across concurrent `autoname` processes.
#[derive(Debug, Clone)]
pub struct GlobalCache {
    cache_dir: PathBuf,
}

impl GlobalCache {
    /// Returns the canonical system-wide cache instance.
    /// Uses `/dev/shm` (in-memory RAM disk) on Linux and kernel page cache (`temp_dir`) on macOS.
    pub fn instance() -> Self {
        let cache_dir = if let Ok(dir) = std::env::var("AUTONAME_CACHE_DIR") {
            PathBuf::from(dir)
        } else if cfg!(target_os = "linux") && PathBuf::from("/dev/shm").exists() {
            PathBuf::from("/dev/shm").join("autoname_cache_v1")
        } else {
            std::env::temp_dir().join("autoname_cache_v1")
        };
        let _ = fs::create_dir_all(&cache_dir);
        Self { cache_dir }
    }

    /// Creates a custom cache instance (useful for unit testing).
    pub fn new(cache_dir: PathBuf) -> Self {
        let _ = fs::create_dir_all(&cache_dir);
        Self { cache_dir }
    }

    /// Returns the cached string value for `key` if it exists and is younger than `ttl`.
    /// Otherwise returns `None`.
    pub fn get(&self, key: &str, ttl: Duration) -> Option<String> {
        let file_path = self.cache_dir.join(key);
        let metadata = fs::metadata(&file_path).ok()?;
        let modified = metadata.modified().ok()?;

        if SystemTime::now().duration_since(modified).ok()? > ttl {
            return None;
        }

        fs::read_to_string(&file_path).ok()
    }

    /// Stores `value` for `key` using atomic write-and-rename to prevent corrupted reads
    /// across concurrent `autoname` processes.
    pub fn set(&self, key: &str, value: &str) {
        let file_path = self.cache_dir.join(key);
        let tmp_path = self.cache_dir.join(format!("{}.tmp.{}", key, std::process::id()));
        if let Ok(mut f) = File::create(&tmp_path) {
            if f.write_all(value.as_bytes()).is_ok() && f.flush().is_ok() {
                let _ = fs::rename(&tmp_path, &file_path);
            } else {
                let _ = fs::remove_file(&tmp_path);
            }
        }
    }

    /// Helper that gets from cache or computes `value` via `fetcher` if expired or missing,
    /// storing the result in the cache for `ttl`.
    pub fn get_or_compute<F>(&self, key: &str, ttl: Duration, fetcher: F) -> Option<String>
    where
        F: FnOnce() -> Option<String>,
    {
        if let Some(cached) = self.get(key, ttl) {
            return Some(cached);
        }
        if let Some(computed) = fetcher() {
            self.set(key, &computed);
            return Some(computed);
        }
        None
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::thread::sleep;

    #[test]
    fn test_global_cache_get_and_set() {
        let _guard = ENV_TEST_MUTEX.lock().unwrap_or_else(|e| e.into_inner());
        let dir = std::env::temp_dir().join("autoname_test_cache_get_set");
        let _ = fs::remove_dir_all(&dir);
        let cache = GlobalCache::new(dir.clone());

        assert!(cache.get("mykey", Duration::from_secs(10)).is_none());

        cache.set("mykey", "cached_value_42");
        assert_eq!(
            cache.get("mykey", Duration::from_secs(10)),
            Some("cached_value_42".to_string())
        );

        let _ = fs::remove_dir_all(&dir);
    }

    #[test]
    fn test_global_cache_expiration() {
        let _guard = ENV_TEST_MUTEX.lock().unwrap_or_else(|e| e.into_inner());
        let dir = std::env::temp_dir().join("autoname_test_cache_expiration");
        let _ = fs::remove_dir_all(&dir);
        let cache = GlobalCache::new(dir.clone());

        cache.set("short_lived", "expired_soon");
        sleep(Duration::from_millis(50));

        assert!(cache.get("short_lived", Duration::from_millis(10)).is_none());

        let _ = fs::remove_dir_all(&dir);
    }

    #[test]
    fn test_get_or_compute_caches_result() {
        let _guard = ENV_TEST_MUTEX.lock().unwrap_or_else(|e| e.into_inner());
        let dir = std::env::temp_dir().join("autoname_test_cache_get_or_compute");
        let _ = fs::remove_dir_all(&dir);
        let cache = GlobalCache::new(dir.clone());

        let mut compute_count = 0;
        let res1 = cache.get_or_compute("counter", Duration::from_secs(10), || {
            compute_count += 1;
            Some("computed_once".to_string())
        });
        assert_eq!(res1, Some("computed_once".to_string()));
        assert_eq!(compute_count, 1);

        let res2 = cache.get_or_compute("counter", Duration::from_secs(10), || {
            compute_count += 1;
            Some("computed_twice".to_string())
        });
        assert_eq!(res2, Some("computed_once".to_string()));
        assert_eq!(compute_count, 1);

        let _ = fs::remove_dir_all(&dir);
    }
}
