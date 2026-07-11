function hamsi_accept --description "Accept the active autocompletion suggestion"
    if test "$hamsi_in_preview" = 1
        set -l current_buffer (commandline -b)
        set -l current_cursor (commandline -C)
        if test "$current_buffer" = "$hamsi_original_buffer"; and test $current_cursor -eq $hamsi_original_cursor
            # Buffer hasn't changed, insert suggestion
            commandline -i "$hamsi_suggestion"
        end
        set -e hamsi_in_preview
        set -e hamsi_original_buffer
        set -e hamsi_original_cursor
        set -e hamsi_suggestion
        commandline -f repaint
    else
        # Fallback to the original action of the accept keybinding
        switch "$hamsi_accept_keybinding"
            case \cy
                commandline -f yank
            case \cf right \e\[C
                commandline -f forward-char
            case \t tab
                commandline -f complete
            case '*'
                # Generic repaint if no specific fallback is matched
                commandline -f repaint
        end
    end
end
