use crate::{get_socket_path, parser, retriever, validator, Args};
use anyhow::Result;
use notify::{Event, RecursiveMode, Watcher};
use std::fs;
use std::sync::Arc;
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::net::UnixListener;
use tokio::sync::RwLock;

pub async fn run() -> Result<()> {
    let app_config: Arc<RwLock<parser::AppConfig>> = match parser::parse_autoname_config() {
        Ok(config) => Arc::new(RwLock::new(config)),
        Err(e) => {
            eprintln!("[autoname] error loading configuration: {}", e);
            std::process::exit(1);
        }
    };

    let socket_path = get_socket_path();
    // Clean up any old socket file
    if fs::metadata(&socket_path).is_ok() {
        fs::remove_file(&socket_path)?;
    }

    let listener = UnixListener::bind(&socket_path)?;
    println!("[autoname] daemon started, listening on {}", socket_path);

    // Watch for config changes
    let config_clone = app_config.clone();
    let mut watcher = notify::recommended_watcher(move |res: Result<Event, notify::Error>| {
        if res.is_ok() {
            println!("[autoname] config changed, reloading...");
            match parser::parse_autoname_config() {
                Ok(new_config) => {
                    let mut config_guard = config_clone.blocking_write();
                    *config_guard = new_config;
                    println!("[autoname] config reloaded successfully");
                }
                Err(e) => {
                    eprintln!("[autoname] error reloading config: {}", e);
                }
            }
        }
    })?;

    if let Some(home_dir) = dirs::home_dir() {
        let config_path = home_dir.join(".tmux").join("autoname.toml");
        watcher.watch(&config_path, RecursiveMode::NonRecursive)?;
    }

    loop {
        match listener.accept().await {
            Ok((mut stream, _addr)) => {
                let app_config = app_config.clone();
                tokio::spawn(async move {
                    let mut buffer = Vec::new();
                    if let Err(e) = stream.read_to_end(&mut buffer).await {
                        eprintln!("[autoname] failed to read from stream: {}", e);
                        return;
                    }

                    let args: Args = match bincode::deserialize(&buffer) {
                        Ok(args) => args,
                        Err(e) => {
                            eprintln!("[autoname] failed to deserialize args: {}", e);
                            return;
                        }
                    };
                    
                    if let Err(e) = validator::validate_args(&args) {
                        eprintln!("[autoname] validation Error: {}", e);
                        return;
                    }

                    let config_guard = app_config.read().await;
                    let process_name = args.process_name.as_deref().unwrap_or_default();
                    let working_directory = args.working_directory.as_deref().unwrap_or_default();

                    let tab_appearance = retriever::compute_tab_appearance(
                        process_name,
                        working_directory,
                        &config_guard,
                    );

                    let output_value = match args.retrieve.as_deref() {
                        Some("tab_icon") => tab_appearance.icon + " ",
                        Some("tab_name") => tab_appearance.name,
                        Some("tab_colour") => tab_appearance.colour,
                        _ => String::new(),
                    };

                    if let Err(e) = stream.write_all(output_value.as_bytes()).await {
                        eprintln!("[autoname] failed to write to stream: {}", e);
                    }
                });
            }
            Err(e) => {
                eprintln!("[autoname] failed to accept connection: {}", e);
            }
        }
    }
} 