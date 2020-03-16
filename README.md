# splitapt
Split single `apt upgrade` into multiple `apt upgrade` commands.  
Between every `apt upgrade`s, `sync` will be done to prevent I/O error.