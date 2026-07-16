use crate::bottombar::extension::{Extension, ExtensionContext, ExtensionOutput};
use crate::constants::{colours, icons};
use std::collections::{HashMap, HashSet};
use std::process::Command;
use sysinfo::System;

/// Extension that detects if any descendant process inside `#{pane_pid}` is actively listening on a TCP port (`:3000`).
pub struct PortsExtension;

impl Extension for PortsExtension {
    fn name(&self) -> &'static str {
        "ports"
    }

    fn compute(&self, ctx: &ExtensionContext) -> Option<ExtensionOutput> {
        let pid = ctx.pane_pid?;
        if pid == 0 {
            return None;
        }

        let mut sys = System::new();
        let pids = crate::bottombar::retriever::get_pane_process_tree(pid, &mut sys);
        let mut ports = HashSet::new();

        if let Ok(inode_map) = parse_proc_net_tcp()
            && !inode_map.is_empty()
        {
            for target_pid in &pids {
                let fd_dir = format!("/proc/{}/fd", target_pid.as_u32());
                if let Ok(entries) = std::fs::read_dir(fd_dir) {
                    for entry in entries.flatten() {
                        if let Ok(target) = std::fs::read_link(entry.path())
                            && let Some(target_str) = target.to_str()
                            && let Some(inode_str) = target_str
                                .strip_prefix("socket:[")
                                .and_then(|s| s.strip_suffix(']'))
                            && let Ok(inode) = inode_str.parse::<u64>()
                            && let Some(&port) = inode_map.get(&inode)
                        {
                            ports.insert(port);
                        }
                    }
                }
            }
        }

        if ports.is_empty() && !pids.is_empty() {
            let pid_strs: Vec<String> = pids.iter().map(|p| p.as_u32().to_string()).collect();
            let pid_arg = pid_strs.join(",");
            if let Ok(output) = Command::new("lsof")
                .args(["-a", "-p", &pid_arg, "-iTCP", "-sTCP:LISTEN", "-P", "-n"])
                .output()
                && output.status.success()
                && let Ok(out_str) = std::str::from_utf8(&output.stdout)
            {
                for line in out_str.lines().skip(1) {
                    if let Some(pos) = line.rfind("TCP ") {
                        let part = &line[pos + 4..];
                        if let Some(space_pos) = part.find(' ') {
                            let addr = &part[..space_pos];
                            if let Some(colon_pos) = addr.rfind(':')
                                && let Ok(port) = addr[colon_pos + 1..].parse::<u16>()
                            {
                                ports.insert(port);
                            }
                        }
                    }
                }
            }
        }

        if ports.is_empty() {
            return None;
        }

        let mut sorted_ports: Vec<u16> = ports.into_iter().collect();
        sorted_ports.sort_unstable();
        let port_strs: Vec<String> = sorted_ports.into_iter().map(|p| format!(":{}", p)).collect();
        let text = port_strs.join(", ");

        Some(ExtensionOutput {
            icon: icons::PORT.to_string(),
            colour: colours::GREEN.to_string(),
            text,
        })
    }
}

fn parse_proc_net_tcp() -> Result<HashMap<u64, u16>, std::io::Error> {
    let mut map = HashMap::new();
    for path in &["/proc/net/tcp", "/proc/net/tcp6"] {
        if let Ok(content) = std::fs::read_to_string(path) {
            for line in content.lines().skip(1) {
                let parts: Vec<&str> = line.split_whitespace().collect();
                if parts.len() >= 10 {
                    let local_addr = parts[1];
                    let state = parts[3];
                    let inode_str = parts[9];
                    if state.eq_ignore_ascii_case("0A")
                        && let Some(colon_pos) = local_addr.rfind(':')
                        && let Ok(port) = u16::from_str_radix(&local_addr[colon_pos + 1..], 16)
                        && let Ok(inode) = inode_str.parse::<u64>()
                    {
                        map.insert(inode, port);
                    }
                }
            }
        }
    }
    Ok(map)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::bottombar::extension::test_utils::TestContextBuilder;

    #[test]
    fn test_ports_extension_returns_none_when_pid_zero() {
        let builder = TestContextBuilder::new().pane_pid(Some(0));
        let ctx = builder.build();

        let ext = PortsExtension;
        assert!(ext.compute(&ctx).is_none());
    }

    #[test]
    fn test_ports_extension_returns_none_when_pid_none() {
        let builder = TestContextBuilder::new().pane_pid(None);
        let ctx = builder.build();

        let ext = PortsExtension;
        assert!(ext.compute(&ctx).is_none());
    }
}
