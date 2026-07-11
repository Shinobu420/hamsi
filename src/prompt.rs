use std::process::Command;
use std::collections::HashSet;
use std::env;
use std::fs;
use serde_json::{json, Value};

const COMMON_TOOLS: &[&str] = &[
    "git", "docker", "cargo", "npm", "pnpm", "yarn", "pip", "poetry",
    "python", "python3", "node", "go", "rustc", "gcc", "make", "clang",
    "rg", "fd", "bat", "fzf", "kubectl", "aws", "gcloud", "sqlite3",
    "curl", "wget", "tmux", "vim", "nvim", "nano"
];

fn get_git_branch() -> Option<String> {
    let output = Command::new("git")
        .args(&["branch", "--show-current"])
        .output()
        .ok()?;
    
    if output.status.success() {
        let branch = String::from_utf8_lossy(&output.stdout).trim().to_string();
        if !branch.is_empty() {
            return Some(branch);
        }
    }
    None
}

fn get_git_status() -> Option<String> {
    let output = Command::new("git")
        .args(&["status", "--short"])
        .output()
        .ok()?;
    
    if output.status.success() {
        let status = String::from_utf8_lossy(&output.stdout).trim().to_string();
        if !status.is_empty() {
            return Some(status);
        }
    }
    None
}

fn get_current_dir_name() -> Option<String> {
    let cwd = std::env::current_dir().ok()?;
    cwd.file_name()
        .and_then(|n| n.to_str())
        .map(|s| s.to_string())
}

fn get_installed_tools() -> String {
    let mut installed = Vec::new();
    let path_var = match env::var("PATH") {
        Ok(p) => p,
        Err(_) => return String::new(),
    };

    let mut path_binaries = HashSet::new();
    for path in env::split_paths(&path_var) {
        if let Ok(entries) = fs::read_dir(path) {
            for entry in entries {
                if let Ok(entry) = entry {
                    if let Ok(file_type) = entry.file_type() {
                        if file_type.is_file() || file_type.is_symlink() {
                            if let Some(name) = entry.file_name().to_str() {
                                path_binaries.insert(name.to_string());
                            }
                        }
                    }
                }
            }
        }
    }

    for tool in COMMON_TOOLS {
        if path_binaries.contains(*tool) {
            installed.push(*tool);
        }
    }

    installed.join(", ")
}

pub fn build_payload(
    prompt_format: &str,
    model: &str,
    text_before: &str,
    text_after: &str,
    local_files: &str,
    history: &[String],
    allow_chaining: bool,
) -> Value {
    if prompt_format == "fim" {
        let mut prefix = String::new();
        if let Some(dir) = get_current_dir_name() {
            prefix.push_str(&format!("# Directory: {}\n", dir));
        }
        if let Some(branch) = get_git_branch() {
            prefix.push_str(&format!("# Git branch: {}\n", branch));
        }
        if let Some(status) = get_git_status() {
            prefix.push_str("# Git status:\n");
            for line in status.lines() {
                prefix.push_str(&format!("#   {}\n", line));
            }
        }
        let tools = get_installed_tools();
        if !tools.is_empty() {
            prefix.push_str(&format!("# Installed tools: {}\n", tools));
        }
        if !history.is_empty() {
            prefix.push_str("# Recent history:\n");
            for cmd in history {
                prefix.push_str(&format!("# - {}\n", cmd));
            }
        }
        if !local_files.is_empty() {
            prefix.push_str(&format!("# Files in directory: {}\n", local_files));
        }
        prefix.push_str("# Note: Complete only the current command. Do not chain commands or add pipes (|).\n");
        prefix.push_str(text_before);

        let prompt = format!("<|fim_prefix|>{prefix}<|fim_suffix|>{text_after}<|fim_middle|>");

        let stop_tokens = if allow_chaining {
            vec!["\n".to_string(), "<|file_separator|>".to_string()]
        } else {
            vec![
                "\n".to_string(),
                "<|file_separator|>".to_string(),
                "|".to_string(),
                ";".to_string(),
                "&&".to_string(),
            ]
        };

        json!({
            "model": model,
            "prompt": prompt,
            "raw": true,
            "stream": false,
            "options": {
                "num_predict": 50,
                "temperature": 0.0,
                "stop": stop_tokens
            }
        })
    } else {
        let system_prompt = "You are a terminal autocomplete AI. You must output ONLY a JSON object containing the exact characters to append to the user's input. Do NOT repeat the user's input. Complete only the current command and do NOT chain commands or add pipes (|). Format: {\"completion\": \"suffix_here\"}";

        let mut prompt = String::new();
        if let Some(dir) = get_current_dir_name() {
            prompt.push_str(&format!("Current directory: {}\n", dir));
        }
        if let Some(branch) = get_git_branch() {
            prompt.push_str(&format!("Git branch: {}\n", branch));
        }
        if let Some(status) = get_git_status() {
            prompt.push_str("Git status:\n");
            for line in status.lines() {
                prompt.push_str(&format!("  {}\n", line));
            }
        }
        let tools = get_installed_tools();
        if !tools.is_empty() {
            prompt.push_str(&format!("Installed tools: {}\n", tools));
        }
        prompt.push_str("Recent history:\n");
        for cmd in history {
            prompt.push_str(&format!("- {}\n", cmd));
        }
        if !local_files.is_empty() {
            prompt.push_str(&format!("\nFiles in current directory: {}\n", local_files));
        }
        prompt.push_str(&format!("\nCurrent command line:\n{}\n", text_before));

        let stop_tokens = if allow_chaining {
            vec!["\n".to_string()]
        } else {
            vec![
                "\n".to_string(),
                "|".to_string(),
                ";".to_string(),
                "&&".to_string(),
            ]
        };

        json!({
            "model": model,
            "system": system_prompt,
            "prompt": prompt,
            "format": "json",
            "stream": false,
            "options": {
                "num_predict": 50,
                "temperature": 0.0,
                "stop": stop_tokens
            }
        })
    }
}
