use std::fs;
use std::path::PathBuf;

#[derive(Debug)]
pub struct Config {
    pub model: String,
    pub api_url: String,
    pub prompt_format: String,
    pub history_limit: usize,
    pub allow_chaining: bool,
}

impl Default for Config {
    fn default() -> Self {
        Config {
            model: "qwen2.5-coder:1.5b".to_string(),
            api_url: "http://localhost:11434/api/generate".to_string(),
            prompt_format: "".to_string(), // Will be auto-detected below if empty
            history_limit: 5,
            allow_chaining: false,
        }
    }
}

impl Config {
    pub fn load() -> Self {
        let mut config = Config::default();
        let home = match std::env::var("HOME") {
            Ok(h) => h,
            Err(_) => return config,
        };

        let config_path = PathBuf::from(home)
            .join(".config")
            .join("hamsi")
            .join("hamsi.conf");

        if !config_path.exists() {
            // Auto-detect prompt format if config file does not exist
            if config.prompt_format.is_empty() {
                if config.model.contains("coder") {
                    config.prompt_format = "fim".to_string();
                } else {
                    config.prompt_format = "json".to_string();
                }
            }
            return config;
        }

        let content = match fs::read_to_string(config_path) {
            Ok(c) => c,
            Err(_) => return config,
        };

        for line in content.lines() {
            let line = line.trim();
            if line.is_empty() || line.starts_with('#') {
                continue;
            }

            let parts: Vec<&str> = line.splitn(2, '=').collect();
            if parts.len() != 2 {
                continue;
            }

            let key = parts[0].trim();
            let mut val = parts[1].trim().to_string();

            // Strip enclosing quotes if present
            if (val.starts_with('"') && val.ends_with('"')) || (val.starts_with('\'') && val.ends_with('\'')) {
                val.remove(0);
                val.pop();
            }

            match key {
                "model" => config.model = val,
                "api_url" => config.api_url = val,
                "prompt_format" => config.prompt_format = val,
                "history_limit" => {
                    if let Ok(limit) = val.parse::<usize>() {
                        config.history_limit = limit;
                    }
                }
                "allow_chaining" => {
                    if let Ok(b) = val.parse::<bool>() {
                        config.allow_chaining = b;
                    }
                }
                _ => {}
            }
        }

        // Auto-detect prompt format if not explicitly set
        if config.prompt_format.is_empty() {
            if config.model.contains("coder") {
                config.prompt_format = "fim".to_string();
            } else {
                config.prompt_format = "json".to_string();
            }
        }

        config
    }
}
