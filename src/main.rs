mod cli;
mod config;
mod prompt;
mod client;
mod slicer;
mod ipc;

use std::process;

fn main() {
    let args = match cli::Args::parse() {
        Ok(a) => a,
        Err(e) => {
            eprintln!("Error: {}", e);
            process::exit(1);
        }
    };

    let pid = args.pid.unwrap();

    if let Err(e) = run(&args) {
        eprintln!("Hamsi error: {}", e);
        // On error, write an empty suggestion and signal the parent to clear loading indicator
        let _ = ipc::write_suggestion(pid, "");
        let _ = ipc::signal_parent(pid);
        process::exit(1);
    }
}

fn run(args: &cli::Args) -> Result<(), String> {
    // Load config from hamsi.conf file
    let mut cfg = config::Config::load();

    // Override config values with CLI args if specified
    if !args.model.is_empty() {
        cfg.model = args.model.clone();
    }
    if !args.api_url.is_empty() {
        cfg.api_url = args.api_url.clone();
    }
    if !args.prompt_format.is_empty() {
        cfg.prompt_format = args.prompt_format.clone();
    }

    let payload = prompt::build_payload(
        &cfg.prompt_format,
        &cfg.model,
        &args.text_before,
        &args.text_after,
        &args.local_files,
        &args.history,
        cfg.allow_chaining,
    );

    let raw_resp = client::query_ollama(&cfg.api_url, &payload)?;
    let suggestion = client::parse_suggestion(&cfg.prompt_format, &raw_resp, cfg.allow_chaining)
        .ok_or_else(|| "Failed to parse suggestion".to_string())?;

    let sliced = slicer::slice_suggestion(&args.text_before, &suggestion);

    ipc::write_suggestion(args.pid.unwrap(), &sliced)?;
    ipc::signal_parent(args.pid.unwrap())?;
    Ok(())
}
