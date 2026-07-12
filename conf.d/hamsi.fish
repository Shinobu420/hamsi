# Hamsi - LLM-based Autocompletion for Fish Shell
# Configuration and Initialization

# 1. Load custom config from hamsi.conf if it exists
if test -f ~/.config/hamsi/hamsi.conf
    while read -la line
        # Skip comments and empty lines
        if string match -q -r '^\s*#' "$line"; or test -z (string trim "$line")
            continue
        end
        # Parse key=value
        set -l kv (string split -m 1 "=" $line)
        if test (count $kv) -eq 2
            set -l key (string trim $kv[1])
            set -l val (string trim $kv[2])
            # Strip enclosing quotes if present
            set val (string replace -r '^["\'](.*)["\']$' '$1' "$val")
            set -g hamsi_$key "$val"
        end
    end < ~/.config/hamsi/hamsi.conf
end

# 2. Default configurations (if not already defined by config file)
set -q hamsi_model; or set -g hamsi_model "qwen2.5-coder:1.5b"
set -q hamsi_api_url; or set -g hamsi_api_url "http://localhost:11434/api/generate"
set -q hamsi_history_limit; or set -g hamsi_history_limit 5
set -q hamsi_keybinding; or set -g hamsi_keybinding \co   # Ctrl+O
set -q hamsi_accept_keybinding; or set -g hamsi_accept_keybinding \cy # Ctrl+Y

# Auto-detect prompt format based on model name
set -q hamsi_prompt_format; or begin
    if string match -qi "*coder*" "$hamsi_model"
        set -g hamsi_prompt_format "fim"
    else
        set -g hamsi_prompt_format "json"
    end
end

# Initialize state variables
set -g hamsi_in_preview 0
set -g hamsi_original_buffer ""
set -g hamsi_original_cursor 0
set -g hamsi_suggestion ""

# Configure hamsi_bin path
set -q hamsi_bin; or begin
    if test -f ~/.config/hamsi/bin/hamsi
        set -g hamsi_bin ~/.config/hamsi/bin/hamsi
    else
        set -g hamsi_bin hamsi
    end
end

# Source signal handler explicitly so it registers the trap
if test -f (status dirname)/../functions/hamsi_callback.fish
    source (status dirname)/../functions/hamsi_callback.fish
end

# 2. Register keybindings
function __hamsi_key_bindings --on-variable fish_key_bindings
    # Standard/Emacs mode bindings
    bind $hamsi_keybinding hamsi_trigger
    bind $hamsi_accept_keybinding hamsi_accept
    bind \cg hamsi_discard

    # Vi Insert mode bindings
    bind -M insert $hamsi_keybinding hamsi_trigger
    bind -M insert $hamsi_accept_keybinding hamsi_accept
    bind -M insert \cg hamsi_discard
end

# Apply bindings immediately
__hamsi_key_bindings
