function hamsi_enter --description "Handle Enter keypress, discarding active preview before executing the original command"
    if test "$hamsi_in_preview" = 1
        hamsi_discard
    end
    commandline -f execute
end
