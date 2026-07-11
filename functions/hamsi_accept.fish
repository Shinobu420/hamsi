function hamsi_accept --description "Accept the active autocompletion suggestion"
    if test "$hamsi_in_preview" = 1
        set -l new_cursor (math $hamsi_original_cursor + (string length "$hamsi_suggestion"))
        commandline -C $new_cursor
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
