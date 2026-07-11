#!/usr/bin/env fish

# Define destination directories
set -l fish_config_dir "$HOME/.config/fish"
set -l conf_target "$fish_config_dir/conf.d"
set -l func_target "$fish_config_dir/functions"

# Ensure directories exist
mkdir -p $conf_target
mkdir -p $func_target

# Determine source directory of the script
set -l src_dir (dirname (status filename))

echo "Installing Hamsi..."

#Copy configurations
echo "  -> Copying conf.d/hamsi.fish"
cp "$src_dir/conf.d/hamsi.fish" "$conf_target/hamsi.fish"

#Copy functions
echo "  -> Copying function files"
for f in "$src_dir/functions/"hamsi_*.fish
    cp "$f" "$func_target/"
end

#Setup template custom config directory if not present
mkdir -p "$HOME/.config/hamsi"
if not test -f "$HOME/.config/hamsi/config.fish"
    echo "# Custom Hamsi Settings
#
# Choose your locally hosted Ollama model
# set -g hamsi_model \"qwen2.5-coder:1.5b\"
#
# Prompt format format (\"fim\" or \"json\")
# set -g hamsi_prompt_format \"fim\"
" > "$HOME/.config/hamsi/config.fish"
    echo "  -> Created template configuration at ~/.config/hamsi/config.fish"
end

#Activate in current shell
if test -f "$conf_target/hamsi.fish"
    source "$conf_target/hamsi.fish"
    echo "  -> Hamsi sourced and active!"
end

echo "Hamsi successfully installed! Press Ctrl+O to trigger autocompletion."
