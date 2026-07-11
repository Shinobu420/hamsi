function hamsi_discard --description "Discard the active autocompletion suggestion and restore original command line"
    if test "$hamsi_in_preview" = 1
        commandline -r "$hamsi_original_buffer"
        commandline -C $hamsi_original_cursor
        set -e hamsi_in_preview
        set -e hamsi_original_buffer
        set -e hamsi_original_cursor
        set -e hamsi_suggestion
        commandline -f repaint
    end
end
