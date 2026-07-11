function hamsi_trigger --description "Fetch autocompletion from Ollama and show inline preview"
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

        set -l json_payload ""
        if test "$hamsi_prompt_format" = "fim"
            # Qwen FIM prompt structure: <|fim_prefix|>...<|fim_suffix|>...<|fim_middle|>
            set -l prefix ""
            if test (count $reversed) -gt 0
                set prefix "$prefix# Recent history:\n"
                for cmd in $reversed
                    set prefix "$prefix# - $cmd\n"
                end
            end
            if test -n "$local_files"
                set prefix "$prefix# Files in directory: $local_files\n"
            end
            set prefix "$prefix$text_before"

            set -l prompt "<|fim_prefix|>$prefix<|fim_suffix|>$text_after<|fim_middle|>"

            set json_payload (jq -n --arg model "$hamsi_model" --arg prompt "$prompt" '{
                model: $model,
                prompt: $prompt,
                raw: true,
                stream: false,
                options: {
                    num_predict: 50,
                    temperature: 0.0,
                    stop: ["\n", "<|file_separator|>"]
                }
            }')
        else
            # JSON format prompt structure
            set -l system_prompt "You are a terminal autocomplete AI. You must output ONLY a JSON object containing the exact characters to append to the user's input. Do NOT repeat the user's input. Format: {\"completion\": \"suffix_here\"}"
            
            set -l prompt "Recent history:\n"
            for cmd in $reversed
                set prompt "$prompt- $cmd\n"
            end
            if test -n "$local_files"
                set prompt "$prompt\nFiles in current directory: $local_files\n"
            end
            set prompt "$prompt\nCurrent command line:\n$text_before\n"

            set json_payload (jq -n --arg model "$hamsi_model" --arg sys "$system_prompt" --arg prompt "$prompt" '{
                model: $model,
                system: $sys,
                prompt: $prompt,
                format: "json",
                stream: false,
                options: {
                    num_predict: 50,
                    temperature: 0.0,
                    stop: ["\n"]
                }
            }')
        end

        # Run curl to call Ollama
        set -l response (curl -s --connect-timeout 2 --max-time 5 -X POST -H "Content-Type: application/json" -d "$json_payload" "$hamsi_api_url")
        set -l curl_status $status

        # Clear loading indicator
        printf "\e[s\e[K\e[u"
        commandline -f repaint

        if test $curl_status -ne 0; or test -z "$response"
            return 1
        end

        # Extract suggestion based on format
        set -l suggestion ""
        if test "$hamsi_prompt_format" = "fim"
            set suggestion (echo "$response" | jq -r '.response // empty' 2>/dev/null)
        else
            set suggestion (echo "$response" | jq -r '.response // "{}"' 2>/dev/null | jq -r '.completion // empty' 2>/dev/null)
        end

        if test -n "$suggestion"
            # Middlelayer logic: slice off repeated prefix if it repeated the whole line or last word
            if string match -q -- "$text_before*" "$suggestion"
                set suggestion (string sub -s (math 1 + (string length "$text_before")) "$suggestion")
            else
                # check if it repeated the last word
                set -l last_word (string match -r -- '\S+$' "$text_before")
                if test -n "$last_word"; and string match -q -- "$last_word*" "$suggestion"
                    set suggestion (string sub -s (math 1 + (string length "$last_word")) "$suggestion")
                end
            end
            
            # Avoid empty suggestions after slicing
            if test -z "$suggestion"
                return
            end

            set -g hamsi_in_preview 1
            set -g hamsi_original_buffer "$current_buffer"
            set -g hamsi_original_cursor $cursor_pos
            set -g hamsi_suggestion "$suggestion"

            # Insert suggestion at current cursor
            commandline -i "$suggestion"
            # Return cursor to original position so suggestion appears as ghost text
            commandline -C $cursor_pos
            commandline -f repaint
        end
    end
end
