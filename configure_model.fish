#!/usr/bin/env fish

# Trap Ctrl+C (SIGINT) to exit cleanly
function on_sigint --on-signal SIGINT
    echo ""
    echo "❌ Configuration canceled."
    exit 1
end

echo "Hamsi Model Configuration"
echo "==========================="
echo "Select an Ollama model for autocompletion (FIM-supported):"
echo ""
echo "1) qwen3:0.6b          (Super lightweight, fast completion - ~390MB)"
echo "2) qwen3:1.7b          (Lightweight, excellent speed - ~1.1GB)"
echo "3) qwen2.5-coder:1.5b  (RECOMMENDED: Fast & lightweight, best for most setups - ~980MB)"
echo "4) qwen2.5-coder:3b    (RECOMMENDED: Great balance of speed & accuracy - ~1.9GB)"
echo "5) qwen2.5-coder:7b    (More accurate, requires 8GB+ VRAM - ~4.7GB)"
echo "6) codegemma:2b        (Google's lightweight coder model - ~1.6GB)"
echo "7) Custom...           (Enter a custom Ollama model name)"
echo ""

set -l choice ""
set -l chosen_model ""
while true
    read -l -p 'echo "Enter choice [1-7]: "' choice
    if test $status -ne 0
        echo ""
        echo "❌ Configuration canceled."
        exit 1
    end
    switch "$choice"
        case 1
            set chosen_model "qwen3:0.6b"
            break
        case 2
            set chosen_model "qwen3:1.7b"
            break
        case 3
            set chosen_model "qwen2.5-coder:1.5b"
            break
        case 4
            set chosen_model "qwen2.5-coder:3b"
            break
        case 5
            set chosen_model "qwen2.5-coder:7b"
            break
        case 6
            set chosen_model "codegemma:2b"
            break
        case 7
            read -l -p 'echo "Enter Ollama model name: "' chosen_model
            if test $status -ne 0
                echo ""
                echo "❌ Configuration canceled."
                exit 1
            end
            if test -n "$chosen_model"
                break
            end
        case '*'
            echo "Invalid choice. Please enter a number between 1 and 7."
    end
end

echo ""
echo "Selected model: $chosen_model"

# Check if model is already downloaded in Ollama
echo "Checking if model is installed locally..."
set -l model_list (curl -s http://localhost:11434/api/tags | jq -r '.models[].name' 2>/dev/null)
if test $status -ne 0
    echo "⚠️ Warning: Ollama API is not reachable on http://localhost:11434."
    echo "Please make sure Ollama is running."
    echo "Press Enter to skip model download and update the config file anyway..."
    read
    if test $status -ne 0
        echo ""
        echo "❌ Configuration canceled."
        exit 1
    end
else
    # Check if the chosen model or chosen_model:latest exists in tags
    set -l model_found 0
    for m in $model_list
        if test "$m" = "$chosen_model"
            set model_found 1
            break
        else if string match -q "$chosen_model:latest" "$m"
            set model_found 1
            break
        else if string match -q "$chosen_model" "$m:latest"
            set model_found 1
            break
        end
    end

    if test $model_found -eq 1
        echo "✅ Model '$chosen_model' is already installed."
    else
        echo "Model '$chosen_model' is missing."
        echo "Do you want to download it now? [Y/n]"
        read -l -p 'echo "> "' confirm
        if test $status -ne 0
            echo ""
            echo "❌ Configuration canceled."
            exit 1
        end
        if not string match -ri '^(n|no)$' "$confirm"
            if command -q ollama
                echo "Running: ollama pull $chosen_model"
                ollama pull $chosen_model
            else
                echo "Downloading via Ollama API (this may take a few minutes)..."
                curl -X POST http://localhost:11434/api/pull -d "{\"name\": \"$chosen_model\"}"
            end
            if test $status -eq 0
                echo "✅ Model successfully downloaded!"
            else
                echo "❌ Error: Failed to download model."
            end
        end
    end
end

# Update config file
set -l conf_file "$HOME/.config/hamsi/hamsi.conf"
set -l conf_dir (dirname "$conf_file")
mkdir -p "$conf_dir"

if not test -f "$conf_file"
    # Copy template if not present
    set -l script_dir (dirname (status filename))
    if test -f "$script_dir/conf.d/hamsi.conf"
        cp "$script_dir/conf.d/hamsi.conf" "$conf_file"
    else
        # fallback template
        echo "model = $chosen_model" > "$conf_file"
    end
end

# Modify model line in hamsi.conf
set -l new_content
set -l updated 0
while read -la line
    # Match active or commented model settings
    if string match -q -r '^\s*#?\s*model\s*=' "$line"
        set -a new_content "model = $chosen_model"
        set updated 1
    else
        set -a new_content "$line"
    end
end < "$conf_file"

if test $updated -eq 1
    string join \n $new_content > "$conf_file"
else
    echo "model = $chosen_model" >> "$conf_file"
end

echo ""
echo "Config file updated! Hamsi will now use '$chosen_model'."
