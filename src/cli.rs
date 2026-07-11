#[derive(Debug, Default)]
pub struct Args {
    pub pid: Option<u32>,
    pub api_url: String,
    pub model: String,
    pub prompt_format: String,
    pub text_before: String,
    pub text_after: String,
    pub local_files: String,
    pub history: Vec<String>,
}

impl Args {
    pub fn parse() -> Result<Self, String> {
        let args: Vec<String> = std::env::args().collect();
        let mut parsed = Args::default();
        let mut i = 1;
        while i < args.len() {
            match args[i].as_str() {
                "--pid" => {
                    if i + 1 < args.len() {
                        parsed.pid = args[i+1].parse::<u32>().ok();
                        i += 2;
                    } else {
                        return Err("Missing value for --pid".to_string());
                    }
                }
                "--api-url" => {
                    if i + 1 < args.len() {
                        parsed.api_url = args[i+1].clone();
                        i += 2;
                    } else {
                        return Err("Missing value for --api-url".to_string());
                    }
                }
                "--model" => {
                    if i + 1 < args.len() {
                        parsed.model = args[i+1].clone();
                        i += 2;
                    } else {
                        return Err("Missing value for --model".to_string());
                    }
                }
                "--prompt-format" => {
                    if i + 1 < args.len() {
                        parsed.prompt_format = args[i+1].clone();
                        i += 2;
                    } else {
                        return Err("Missing value for --prompt-format".to_string());
                    }
                }
                "--text-before" => {
                    if i + 1 < args.len() {
                        parsed.text_before = args[i+1].clone();
                        i += 2;
                    } else {
                        return Err("Missing value for --text-before".to_string());
                    }
                }
                "--text-after" => {
                    if i + 1 < args.len() {
                        parsed.text_after = args[i+1].clone();
                        i += 2;
                    } else {
                        return Err("Missing value for --text-after".to_string());
                    }
                }
                "--local-files" => {
                    if i + 1 < args.len() {
                        parsed.local_files = args[i+1].clone();
                        i += 2;
                    } else {
                        return Err("Missing value for --local-files".to_string());
                    }
                }
                "--history" => {
                    if i + 1 < args.len() {
                        parsed.history.push(args[i+1].clone());
                        i += 2;
                    } else {
                        return Err("Missing value for --history".to_string());
                    }
                }
                _ => {
                    i += 1;
                }
            }
        }

        if parsed.pid.is_none() {
            return Err("Missing required argument --pid".to_string());
        }

        Ok(parsed)
    }
}
