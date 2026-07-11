function hamsi_discard --description "Discard the active autocompletion suggestion"
    if test "$hamsi_in_preview" = 1
        set -e hamsi_in_preview
        set -e hamsi_original_buffer
        set -e hamsi_original_cursor
        set -e hamsi_suggestion
        commandline -f repaint
    end
end
