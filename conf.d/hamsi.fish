# Hamsi - LLM-based Autocompletion for Fish Shell
# Configuration and Initialization

# 1. Default configurations (if not already defined by the user)
set -q hamsi_model; or set -g hamsi_model "qwen2.5-coder:1.5b" # default to a lightweight coder model
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

# Load custom config if it exists
if test -f ~/.config/hamsi/config.fish
    source ~/.config/hamsi/config.fish
end

# Initialize state variables
set -g hamsi_in_preview 0
set -g hamsi_original_buffer ""
set -g hamsi_original_cursor 0
set -g hamsi_suggestion ""

# 2. Register keybindings
function __hamsi_key_bindings --on-variable fish_key_bindings
    # Standard/Emacs mode bindings
    bind $hamsi_keybinding hamsi_trigger
    bind $hamsi_accept_keybinding hamsi_accept
    bind \r hamsi_enter
    bind \n hamsi_enter
    bind backspace hamsi_backspace
    bind \cg hamsi_discard

    # Vi Insert mode bindings
    bind -M insert $hamsi_keybinding hamsi_trigger
    bind -M insert $hamsi_accept_keybinding hamsi_accept
    bind -M insert \r hamsi_enter
    bind -M insert \n hamsi_enter
    bind -M insert backspace hamsi_backspace
    bind -M insert \cg hamsi_discard
end

# Apply bindings immediately
__hamsi_key_bindings
