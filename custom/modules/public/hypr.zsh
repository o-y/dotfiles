# restarts hyprlock if the lockscreen freezes up, this should
# be called from a device connected over ssh to the host.
function restart-hyprlock() {
  sudo killall hyprlock
  hyprctl --instance 0 'keyword misc:allow_session_lock_restore 1'
  hyprctl --instance 0 'dispatch exec hyprlock'
}