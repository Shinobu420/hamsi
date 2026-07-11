function hamsi_backspace --description "Handle Backspace keypress, discarding active preview if present"
    if test "$hamsi_in_preview" = 1
        hamsi_discard
    else
        commandline -f backward-delete-char
    end
end
