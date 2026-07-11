#!/usr/bin/env fish

# Define destination directories
set -l fish_config_dir "$HOME/.config/fish"
set -l conf_target "$fish_config_dir/conf.d"
set -l func_target "$fish_config_dir/functions"

# Discard current suggestion if in preview
if functions -q hamsi_discard
    hamsi_discard
end

echo "Uninstalling Hamsi..."

#Remove configuration
if test -f "$conf_target/hamsi.fish"
    echo "  -> Removing conf.d/hamsi.fish"
    rm "$conf_target/hamsi.fish"
end

#Remove functions
echo "  -> Removing function files"
for f in "$func_target/"hamsi_*.fish
    rm -f "$f"
end

#Optional cleanup of custom settings config
echo "Do you want to remove the custom configuration folder (~/.config/hamsi)? [y/N]"
read -l confirm -p 'echo "> "'
if string match -ri '^(y|yes)$' "$confirm"
    rm -rf "$HOME/.config/hamsi"
    echo "  -> Removed custom configurations."
end

echo "Please restart your Fish shell session or open a new terminal to completely clear Hamsi's runtime keybindings."
echo "Hamsi successfully uninstalled!"
