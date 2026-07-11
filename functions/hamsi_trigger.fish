function hamsi_trigger --description "Fetch autocompletion from Ollama and show inline preview asynchronously using Rust backend"
    if test "$hamsi_in_preview" = 1
        hamsi_discard
    else
        set -l current_buffer (commandline -b)
        set -l cursor_pos (commandline -C)

        # Don't complete empty lines
        if test -z (string trim -- "$current_buffer")
            return
        end

        set -l text_before (string sub -s 1 -l $cursor_pos -- "$current_buffer")
        set -l text_after (string sub -s (math $cursor_pos + 1) -- "$current_buffer")

        # Get history (last N commands)
        set -l history_cmds (history -n $hamsi_history_limit)
        set -l reversed
        if test (count $history_cmds) -gt 0
            for i in (seq (count $history_cmds) -1 1)
                set -a reversed $history_cmds[$i]
            end
        end

        # Get files in current directory to provide context (fast builtin wildcard glob)
        set -l local_files (string join ", " * 2>/dev/null | string sub -l 200)

        # Show loading indicator
        printf "\e[s\e[K\e[1;30m [hamsi thinking...]\e[0m\e[u"
        commandline -f repaint

        # Save initial state for verification in callback
        set -g hamsi_original_buffer "$current_buffer"
        set -g hamsi_original_cursor $cursor_pos
        set -g hamsi_in_preview 0

        # Build history arguments
        set -l history_args
        for cmd in $reversed
            set -a history_args --history "$cmd"
        end

        # Run compiled Rust binary in the background (using a safe fallback if hamsi_bin is empty)
        set -l bin_path "hamsi"
        if set -q hamsi_bin; and test -n "$hamsi_bin"
            set bin_path $hamsi_bin
        end

        $bin_path \
            --pid $fish_pid \
            --api-url "$hamsi_api_url" \
            --model "$hamsi_model" \
            --prompt-format "$hamsi_prompt_format" \
            --text-before "$text_before" \
            --text-after "$text_after" \
            --local-files "$local_files" \
            $history_args >/dev/null 2>&1 &
    end
end
