function hamsi_callback --on-signal SIGUSR1 --description "Handle asynchronous LLM completion response"
    set -l sig_file "/tmp/hamsi_suggestion_$fish_pid"
    if not test -f "$sig_file"
        return
    end

    set -l suggestion (cat "$sig_file")
    rm -f "$sig_file"

    # Save current terminal state
    set -l current_buffer (commandline -b)
    set -l current_cursor (commandline -C)

    # Check if current buffer still starts with original buffer
    if not string match -q "$hamsi_original_buffer*" "$current_buffer"
        # User changed the command line completely (e.g. deleted or typed a different command)
        # Clear loading indicator
        printf "\e[s\e[K\e[u"
        commandline -f repaint
        return
    end

    # Calculate what the user has typed since the trigger
    set -l diff_len (math (string length "$current_buffer") - (string length "$hamsi_original_buffer"))
    set -l typed_since ""
    if test $diff_len -gt 0
        set typed_since (string sub -s (math (string length "$hamsi_original_buffer") + 1) -- "$current_buffer")
    end

    set -l remaining_suggestion "$suggestion"
    if test -n "$typed_since"
        if string match -q "$typed_since*" "$suggestion"
            set remaining_suggestion (string sub -s (math (string length "$typed_since") + 1) -- "$suggestion")
        else
            # User typed something that doesn't match the suggestion, so discard it
            printf "\e[s\e[K\e[u"
            commandline -f repaint
            return
        end
    end

    # Clear loading indicator
    printf "\e[s\e[K\e[u"

    if test -z "$remaining_suggestion"
        commandline -f repaint
        return
    end

    # Save state
    set -g hamsi_in_preview 1
    set -g hamsi_original_buffer "$current_buffer"
    set -g hamsi_original_cursor $current_cursor
    set -g hamsi_suggestion "$remaining_suggestion"

    # Render ghost suggestion directly on the screen without modifying commandline buffer
    printf "\e[s\e[1;30m%s\e[0m\e[u" "$remaining_suggestion"
end
