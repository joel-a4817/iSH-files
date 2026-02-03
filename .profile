export XDG_DATA_HOME="$HOME/.local/share"
mkdir -p "$XDG_DATA_HOME/Trash"/{files,info}
alias trash='trash-put --trash-dir "$XDG_DATA_HOME/Trash"'
