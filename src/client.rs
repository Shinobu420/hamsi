use serde_json::Value;

pub fn query_ollama(api_url: &str, payload: &Value) -> Result<String, String> {
    let body = serde_json::to_string(payload).map_err(|e| e.to_string())?;
    let response = minreq::post(api_url)
        .with_header("Content-Type", "application/json")
        .with_body(body)
        .send()
        .map_err(|e| e.to_string())?;

    if response.status_code != 200 {
        return Err(format!("Ollama returned status code: {}", response.status_code));
    }

    let resp_str = response.as_str().map_err(|e| e.to_string())?;
    let resp_json: Value = serde_json::from_str(resp_str).map_err(|e| e.to_string())?;

    Ok(resp_json.get("response")
        .and_then(|r| r.as_str())
        .unwrap_or("")
        .to_string())
}

pub fn parse_suggestion(prompt_format: &str, response_text: &str, allow_chaining: bool) -> Option<String> {
    let suggestion = if prompt_format == "fim" {
        if response_text.is_empty() {
            None
        } else {
            Some(response_text.to_string())
        }
    } else {
        // Parse the inner JSON string returned by Ollama
        let inner_json: Value = serde_json::from_str(response_text).ok()?;
        inner_json.get("completion")
            .and_then(|c| c.as_str())
            .map(|s| s.to_string())
    };

    suggestion.map(|s| {
        let mut end_idx = s.len();
        if let Some(idx) = s.find('\n') {
            end_idx = end_idx.min(idx);
        }
        if !allow_chaining {
            if let Some(idx) = s.find('|') {
                end_idx = end_idx.min(idx);
            }
            if let Some(idx) = s.find(';') {
                end_idx = end_idx.min(idx);
            }
            if let Some(idx) = s.find("&&") {
                end_idx = end_idx.min(idx);
            }
        }
        s[..end_idx].to_string()
    })
}
