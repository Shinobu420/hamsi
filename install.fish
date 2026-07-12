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

# Compile Rust backend
echo "  -> Compiling Rust backend (hamsi)..."
if command -q cargo
    cargo build --release --manifest-path "$src_dir/Cargo.toml"
    if test $status -eq 0
        mkdir -p "$HOME/.config/hamsi/bin"
        cp "$src_dir/target/release/hamsi" "$HOME/.config/hamsi/bin/hamsi"
        echo "  -> Rust backend successfully built and installed to ~/.config/hamsi/bin/hamsi"
    else
        echo "  Error: Failed to compile Rust backend."
        exit 1
    end
else
    echo "  Error: Rust/Cargo is not installed. Please install Rust (https://rustup.rs/) to compile Hamsi."
    exit 1
end
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
if not test -f "$HOME/.config/hamsi/hamsi.conf"
    cp "$src_dir/conf.d/hamsi.conf" "$HOME/.config/hamsi/hamsi.conf"
    echo "  -> Created template configuration at ~/.config/hamsi/hamsi.conf"
end

# Optional model configuration
echo "Do you want to run the Hamsi model configurator now? [Y/n]"
read -l confirm_config -p 'echo "> "'
if not string match -ri '^(n|no)$' "$confirm_config"
    fish "$src_dir/configure_model.fish"
end

#Activate in current shell
if test -f "$conf_target/hamsi.fish"
    source "$conf_target/hamsi.fish"
    echo "  -> Hamsi sourced and active!"
end

echo "Hamsi successfully installed! Press Ctrl+O to trigger autocompletion."
