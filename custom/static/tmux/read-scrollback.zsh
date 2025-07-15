local tmp_file=$(coreutils mktemp "/tmp/tmux-buffer.XXXX")

tmux capture-pane -S -300000
tmux save-buffer "$tmp_file"

tmux new-window "tmux load-buffer $tmp_file && tmux delete-buffer && $EDITOR $tmp_file"