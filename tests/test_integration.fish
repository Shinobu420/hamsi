#!/usr/bin/env fish

# 1. Mock the `commandline` built-in so we can test it non-interactively
set -g mock_buffer ""
set -g mock_cursor 0
set -g mock_inserted ""

function commandline
    if test "$argv[1]" = "-b"
        echo $mock_buffer
    else if test "$argv[1]" = "-C"
        if test (count $argv) -eq 1
            echo $mock_cursor
        else
            set mock_cursor $argv[2]
        end
    else if test "$argv[1]" = "-i"
        set mock_inserted $argv[2]
    else if test "$argv[1]" = "-f"
        # repaint, do nothing
    end
end

# 2. Mock `history` to simulate past commands
function history
    echo "git status"
    echo "git add ."
end

# 3. Source the Hamsi configuration and functions (local)
set -l repo_root (dirname (status filename))/..
set -g hamsi_bin "$repo_root/target/release/hamsi"
source "$repo_root/conf.d/hamsi.fish"
source "$repo_root/functions/hamsi_trigger.fish"
source "$repo_root/functions/hamsi_discard.fish"
source "$repo_root/functions/hamsi_callback.fish"
source "$repo_root/functions/hamsi_accept.fish"

echo "🧪 Running Model Autocomplete Benchmark..."
echo "========================================="

# Get list of locally installed Ollama models
set -l installed_models (curl -s http://localhost:11434/api/tags | jq -r '.models[].name' 2>/dev/null)
if test $status -ne 0
    echo "❌ Error: Cannot connect to Ollama at http://localhost:11434."
    exit 1
end

# The models list from configure_model.fish
set -l candidate_models qwen3:0.6b qwen3:1.7b qwen2.5-coder:1.5b qwen2.5-coder:3b qwen2.5-coder:7b codegemma:2b

# Filter to only run tests on models that are actually installed
set -l models_to_test
for cm in $candidate_models
    for im in $installed_models
        if test "$cm" = "$im"; or string match -q "$cm:latest" "$im"; or string match -q "$cm" "$im:latest"
            set -a models_to_test $im
            break
        end
    end
end

if test (count $models_to_test) -eq 0
    echo "⚠️ No recommended FIM models are currently installed in Ollama."
    echo "Installed models: " (string join ", " $installed_models)
    exit 0
end

# Define test cases: buffer, cursor_pos, description
set -l test_cases \
    "git comm" 8 "Git Commit" \
    "uname -" 7 "Uname Kernel Info" \
    "cat /et" 7 "Cat etc Directory" \
    "docker r" 8 "Docker Run/Remove" \
    "cat configure_m" 15 "Local File"

# Execute tests for each model
for model in $models_to_test
    echo ""
    echo "🤖 Model: $model"
    echo "----------------------------------------"
    
    # Override configured model dynamically
    set -g hamsi_model "$model"
    # Auto-detect prompt format based on model name
    if string match -qi "*coder*" "$model"; or string match -qi "*qwen3*" "$model"
        set -g hamsi_prompt_format "fim"
    else
        set -g hamsi_prompt_format "json"
    end

    set -l case_idx 1
    while test $case_idx -lt (count $test_cases)
        set -l buffer $test_cases[$case_idx]
        set -l cursor $test_cases[(math $case_idx + 1)]
        set -l desc $test_cases[(math $case_idx + 2)]
        
        # Reset mock state
        set -g mock_buffer "$buffer"
        set -g mock_cursor $cursor
        set -g mock_inserted ""
        set -g hamsi_in_preview 0
        set -g hamsi_original_buffer ""
        set -g hamsi_original_cursor 0
        set -g hamsi_suggestion ""

        # Trigger Hamsi (background query)
        hamsi_trigger >/dev/null 2>&1

        # Wait for completion file to be written (up to 5 seconds per test)
        set -l timeout 25
        while test $timeout -gt 0
            if test -f "/tmp/hamsi_suggestion_$fish_pid"
                break
            end
            sleep 0.2
            set timeout (math $timeout - 1)
        end

        # Run signal callback and accept completion
        hamsi_callback >/dev/null 2>&1
        hamsi_accept >/dev/null 2>&1

        # Print test case results
        if test -n "$mock_inserted"
            printf "  %-20s | Input: '%s' -> Suggestion: \e[1;32m%s\e[0m (Final: '%s%s')\n" \
                "$desc" "$buffer" "$mock_inserted" "$buffer" "$mock_inserted"
        else
            printf "  %-20s | Input: '%s' -> Suggestion: \e[1;30m(none)\e[0m\n" \
                "$desc" "$buffer"
        end

        # Clean up any leftover suggestion files
        rm -f "/tmp/hamsi_suggestion_$fish_pid"

        set case_idx (math $case_idx + 3)
    end
end
echo ""
echo "✅ Benchmark completed!"
