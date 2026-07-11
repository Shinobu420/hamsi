pub fn slice_suggestion(text_before: &str, suggestion: &str) -> String {
    let mut res = suggestion.to_string();
    if res.starts_with(text_before) {
        res = res[text_before.len()..].to_string();
    } else {
        // Check if it repeated the last word (must not have trailing whitespace)
        if !text_before.is_empty() && !text_before.ends_with(char::is_whitespace) {
            let last_word_start = text_before
                .rfind(char::is_whitespace)
                .map(|idx| idx + 1)
                .unwrap_or(0);
            let last_word = &text_before[last_word_start..];
            if !last_word.is_empty() && res.starts_with(last_word) {
                res = res[last_word.len()..].to_string();
            }
        }
    }
    res
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_slice_prefix() {
        assert_eq!(slice_suggestion("git comm", "git commit -m"), "it -m");
        assert_eq!(slice_suggestion("git comm", "commit -m"), "it -m");
        assert_eq!(slice_suggestion("git comm ", "commit -m"), "commit -m");
    }
}
