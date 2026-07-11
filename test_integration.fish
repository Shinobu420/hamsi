#!/usr/bin/env fish

# 1. Mock the `commandline` built-in so we can test it non-interactively
set -g mock_buffer "git comm"
set -g mock_cursor 8
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

# 3. Source the Hamsi configuration and functions
source ~/.config/fish/conf.d/hamsi.fish
source ~/.config/fish/functions/hamsi_trigger.fish
source ~/.config/fish/functions/hamsi_discard.fish

echo "🧪 Running integration test..."
echo "Simulating user typing: '$mock_buffer'"

# 4. Trigger Hamsi (which will hit the real Ollama API)
hamsi_trigger

echo ""
echo "✅ Test completed!"
echo "Hamsi injected the following text: '$mock_inserted'"

if test -z "$mock_inserted"
    echo "❌ ERROR: Hamsi failed to generate or inject a completion."
    exit 1
else
    echo "🎉 SUCCESS: Hamsi successfully queried Ollama and processed the result."
end
