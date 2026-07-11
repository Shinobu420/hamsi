use std::fs::File;
use std::io::Write;
use std::path::Path;
use std::process::Command;

pub fn write_suggestion(pid: u32, suggestion: &str) -> Result<(), String> {
    let path_str = format!("/tmp/hamsi_suggestion_{}", pid);
    let path = Path::new(&path_str);
    let mut file = File::create(path).map_err(|e| e.to_string())?;
    file.write_all(suggestion.as_bytes()).map_err(|e| e.to_string())?;
    Ok(())
}

pub fn signal_parent(pid: u32) -> Result<(), String> {
    let pid_str = pid.to_string();
    let status = Command::new("kill")
        .args(&["-USR1", &pid_str])
        .status()
        .map_err(|e| e.to_string())?;

    if status.success() {
        Ok(())
    } else {
        Err("Failed to execute kill command".to_string())
    }
}
